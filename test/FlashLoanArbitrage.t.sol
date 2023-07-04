// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {FlashLoanArbitrage, IDex} from "../src/FlashLoanArbitrage.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {Dex} from "../src/Dex.sol";

contract FlashLoanArbitrageTest is Test {
    FlashLoanArbitrage public flashLoanArbitrage;
    Dex public dex;

    // Mainnet Aave V3 LendingPoolAddressesProvider address
    IPoolAddressesProvider provider = IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    // Mainet ERC20 Token addresseses
    IERC20 private immutable dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private immutable usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        dex = new Dex(dai, usdc);
        flashLoanArbitrage = new FlashLoanArbitrage(provider, dai, usdc, IDex(address(dex)));

        // Add liquidity to the DEX - USDC 1500 DAI 1500
        deal(address(dai), address(dex), 1500e18);
        deal(address(usdc), address(dex), 1500e6);
    }

    function test__constructor() public {
        assertEq(flashLoanArbitrage.owner(), address(this));
        assertEq(flashLoanArbitrage.getDex(), address(dex));
    }

    function test__ArbitrageDemo() public {
        uint256 loanAmount = 1000e6;
        uint256 premium = flashLoanArbitrage.POOL().FLASHLOAN_PREMIUM_TOTAL(); // 0.05%
        uint256 totalDebt = loanAmount + (premium * 1e5); // 1000.5e6
        flashLoanArbitrage.requestFlashLoan(address(usdc), loanAmount);

        // Check the floashloan with arbitrage was successful
        uint256 daiToReceive = ((loanAmount / dex.dexARate()) * 100) * (10 ** 12);
        uint256 usdcToReceive = ((daiToReceive * dex.dexBRate()) / 100) / (10 ** 12);
        uint256 expectedUsdcAmount = usdcToReceive - totalDebt;
        uint256 flashLoanArbitrageUsdcBalance = flashLoanArbitrage.getBalance(address(usdc));

        assertEq(flashLoanArbitrageUsdcBalance, expectedUsdcAmount);

        // Withdraw the profit
        flashLoanArbitrage.withdraw(address(usdc));
        assertEq(usdc.balanceOf(address(this)), expectedUsdcAmount);
        assertEq(flashLoanArbitrage.getBalance(address(usdc)), 0);
    }
}
