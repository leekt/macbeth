pragma solidity ^0.8.14;

import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

contract MockVault {
    mapping(address => uint256) public deposits;

    function deposit(address _token, uint256 _amount) external {
        uint256 bbefore = ERC20(_token).balanceOf(address(this));
        SafeTransferLib.safeTransferFrom(
            ERC20(_token),
            msg.sender,
            address(this),
            _amount
        );
        uint256 bafter = ERC20(_token).balanceOf(address(this));
        deposits[msg.sender] += bafter - bbefore;
    }
}
