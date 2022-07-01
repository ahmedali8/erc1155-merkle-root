// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import { Token } from "contracts/Token.sol";
import { TestUSDT } from "contracts/test/TestUSDT.sol";

contract TokenScript is Script {
    // function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // deploy our contract
        TestUSDT testUSDT = new TestUSDT();
        new Token(address(testUSDT), msg.sender);

        vm.stopBroadcast();
    }
}
