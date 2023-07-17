// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DloopPaymentGovernance is Ownable, Pausable, ReentrancyGuard {
    address private _signingAddress;

    event SigningAddressSet(
        address indexed previousAddress,
        address indexed newAddress
    );

    event ExcessPaymentTokensWithdrawn(
        address indexed tokenAddress,
        address indexed to,
        uint256 amount
    );

    event ExcessEtherWithdrawn(address indexed to, uint256 amount);

    constructor() public {
        _signingAddress = msg.sender;
    }

    function setSigningAddress(address signer) external onlyOwner {
        emit SigningAddressSet(_signingAddress, signer);
        _signingAddress = signer;
    }

    function getSigningAddress() public view returns (address) {
        return _signingAddress;
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    function withdrawExcessPaymentTokens(address to, address tokenAddr)
        external
        nonReentrant
        onlyOwner
    {
        IERC20 token = IERC20(tokenAddr);
        uint256 totalTokens = token.balanceOf(address(this));

        require(
            token.transfer(to, totalTokens),
            "withdrawExcessPaymentTokens failed"
        );
        emit ExcessPaymentTokensWithdrawn(tokenAddr, to, totalTokens);
    }

    function withdrawExcessEther(address payable to)
        external
        nonReentrant
        onlyOwner
    {
        uint256 totalWei = address(this).balance;
        bool result = to.send(totalWei);

        require(result, "withdrawExcessEther failed");
        emit ExcessEtherWithdrawn(to, totalWei);
    }
}