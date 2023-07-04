// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {Dex} from "../src/Dex.sol";
import {IDex, FlashLoanArbitrage} from "../src/FlashLoanArbitrage.sol";

contract DeployFlashLoanArbitrage is Script {
    // Mainnet Aave V3 LendingPoolAddressesProvider address
    IPoolAddressesProvider provider = IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    // Mainet ERC20 Token addresseses
    IERC20 private immutable daiAddress = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private immutable usdcAddress = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function run() public returns (Dex dex, FlashLoanArbitrage flashLoanArbitrage) {
        vm.startBroadcast();
        dex = new Dex(daiAddress, usdcAddress);
        flashLoanArbitrage = new FlashLoanArbitrage(provider, daiAddress, usdcAddress, IDex(address(dex)));
        vm.stopBroadcast();
    }
}
