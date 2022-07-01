// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./utils/Utils.sol";
import "forge-std/test/StdError.t.sol";

contract UtilsTest is Utils {
    function testToWei() public {
        assertEq(this.toWei(2), 2 ether);
    }

    // function testToWeiWithFuzzing(uint256 value) public {
    //     vm.assume(value <= type(uint256).max - 10**18);
    //     vm.assume(value > 0);

    //     if (value == type(uint256).max) vm.expectRevert(stdError.arithmeticError);

    //     assertEq(this.toWei(value), value * 10**18);
    // }

    function testToWeiWithDecimals() public {
        assertEq(this.toWei(2, 6), 2 * 1e6);
    }

    // function testToWeiWithDecimalsWithFuzzing(uint256 value) public {
    //     vm.assume(value + 1e6 <= type(uint256).max - 1e6);
    //     vm.assume(value != 0);

    //     assertEq(this.toWei(value, 6), value * 1e6);
    // }
}
