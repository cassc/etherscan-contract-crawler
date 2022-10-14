// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface BSCNewsNFT is IERC721Enumerable {
    function mint(address _to, uint256 _amount) external payable;
    function setPriceForPublic(uint256 _pricePublic) external;
    function transferOwnership(address newOwner) external;
    function priceForPublic() external view returns (uint256);
    function owner() external view returns (address);
}

contract BSCNewsBABMinter is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    BSCNewsNFT public constant token = BSCNewsNFT(0xD15360dEF9f520c4b6449299d24C5Be08751307E);
    IERC721 public constant bab = IERC721(0x9660ee665B931D8b8E765d6e27C29C48B2Bf8413);
    
    uint256 public reducedPrice = 0.3 ether;

    function setReducedPrice(uint256 _reducedPrice) external onlyOwner {
        reducedPrice = _reducedPrice;
    }

    function recoverOwnership() external onlyOwner {
        token.transferOwnership(owner());
    }

    function recoverOwnership(address target, address newOwner) external onlyOwner {
        Ownable(target).transferOwnership(newOwner);
    }

    function mint(address _to, uint256 _amount) external payable {
        bool hasReducedPrice = _hasReducedPrice(_to);
        uint256 priceForPublic = token.priceForPublic();
        if (hasReducedPrice) {
            token.setPriceForPublic(reducedPrice);
        }
        token.mint{value: msg.value}(_to, _amount);
        if (hasReducedPrice) {
            token.setPriceForPublic(priceForPublic);
        }
    }

    function priceFor(address user)
        external
        view
        returns (uint256)
    {
        return _hasReducedPrice(user) ? reducedPrice : token.priceForPublic();
    }

    function _hasReducedPrice(address user) internal view returns (bool) {
        return token.owner() == address(this) && bab.balanceOf(user) > 0;
    }


    /**
     * @notice Withdraw all payed commissions, only callable by owner.
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyOwner {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);
    }

    /**
     * @notice Allows the owner to recover NFTs sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId)
        external
        onlyOwner
    {
        IERC721(_token).safeTransferFrom(
            address(this),
            address(msg.sender),
            _tokenId
        );
    }
}