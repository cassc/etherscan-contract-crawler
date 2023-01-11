//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleAirdrop {
    IERC20 public constant tefiV1 = IERC20(0xD23a8017B014cB3C461a80D1ED9EC8164c3f7A77);
    function airdrop(address[] calldata _wallets, uint _amount) external {
        for (uint i = 0; i < _wallets.length;) {
            tefiV1.transferFrom(msg.sender, _wallets[i], _amount);
            unchecked {
                ++i;
            }
        }
    }
}