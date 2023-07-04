// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract FlashLoan is FlashLoanSimpleReceiverBase {
    //========== ERRORS ==========//

    error FlashLoan__notOwner();
    error FlashLoan__transferFailed();

    //========== STATE VARIABLES ==========//

    address payable public owner;

    //========== MODIFIERS ==========//

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert FlashLoan__notOwner();
        }
        _;
    }

    //========== EVENTS ==========//

    event FlashLoanRequested(address indexed receiver, address indexed token, uint256 amount);
    event ExecutionOver(address indexed iniator, bytes params, address indexed token, uint256 amountOwed);
    event Withdraw(address indexed token, uint256 amount);

    //========== CONSTRUCTOR ==========//

    constructor(IPoolAddressesProvider _provider) FlashLoanSimpleReceiverBase(_provider) {
        owner = payable(msg.sender);
    }

    //========== FALLBACK ==========//

    receive() external payable {}

    //========== MUTATING FUNCTIONS ==========//

    /**
     * @notice Initiates a flashloan
     * @dev The amount requested will be transferred to this contract before executeOperation is called
     * @param _token The address of the flash-borrowed asset
     * @param _amount The amount of the flash-borrowed asset
     */
    function requestFlashLoan(address _token, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(receiverAddress, asset, amount, params, referralCode);

        emit FlashLoanRequested(receiverAddress, asset, amount);
    }

    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        override
        returns (bool)
    {
        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //

        // At the end of your logic above, this contract owes
        // the flashloaned amount + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the Pool contract allowance to *pull* the owed amount
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        emit ExecutionOver(initiator, params, asset, amountOwed);

        return true;
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);

        emit Withdraw(_tokenAddress, token.balanceOf(address(this)));
        bool success = token.transfer(msg.sender, token.balanceOf(address(this)));
        if (!success) {
            revert FlashLoan__transferFailed();
        }
    }

    //========== VIEW FUNCTIONS ==========//

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }
}
