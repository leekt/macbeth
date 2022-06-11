pragma solidity ^0.8.14;

import "src/FuzzWeirdERC20.sol";

contract TestFuzzWeirdERC20 is FuzzWeirdERC20 {
    function setUp() public {
        deployTokens(address(0xBEEF), 1000);
    }

    function testTransferFrom(uint256 tokenType) external {
        address token = runHappyScenario(tokenType, address(0xBEEF), address(0xCAFE), 100);
        vm.prank(address(0xCAFE));
        ERC20(token).transferFrom(address(0xBEEF), address(0xCAFE), 100);
    }
}
