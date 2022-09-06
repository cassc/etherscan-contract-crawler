// SPDX-License-Identifier: MIT

/// 1000 SuDoges
/// Sudoswap We stealth, we yaff yaff
/// Twitter: https://twitter.com/sudogenfts
/// Telegram: https://t.me/sudogenfts
/// We're only live on Sudoswap, we won't work on any other platforms! Sudoge NFTs are only moveable on Sudoswap.

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./LSSVMPairCloner.sol";
import "./IERC20.sol";

contract SuDoge is ERC721A, Ownable {

    bool _mintingEnabled = true;
    bool _sudoswapOnly;
    string baseURI;

    address constant sudoswapRouter = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    address constant sudoswapFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
    address constant missingEnumerableETHTemplate = 0xCd80C916B1194beB48aBF007D0b79a7238436D56;
    address constant missingEnumerableERC20Template = 0x92de3a1511EF22AbCf3526c302159882a4755B22;

    function mintingEnable() external view returns (bool) {
        return _mintingEnabled;
    }

    function sudoswapOnly() external view returns (bool) {
        return _sudoswapOnly;
    }

    constructor() ERC721A("Sudoge", "SUDOGE") {
        baseURI = "ipfs://QmZLd5vAovekfnsTQTCngcckUWLsLu7Qmfeq7TDw6aXeA5/";
    }

    function ownerMintTo(address receipient, uint256 quantity) external onlyOwner() {
        require(_mintingEnabled, 'Minting has been disabled');
        _safeMint(receipient, quantity);
    }

    function disableMinting() external onlyOwner() {
        _mintingEnabled = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function setSudoswapOnly(bool value) external onlyOwner() {
        _sudoswapOnly = value;
    }

    function withdraw() external onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner() {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        if(!_sudoswapOnly)
            return;
        if(_msgSenderERC721A() == sudoswapRouter || _msgSenderERC721A() == sudoswapFactory)
            return;
        if(!isContract(_msgSenderERC721A()))
            return;
        if(isPair(_msgSenderERC721A(), PairVariant.MISSING_ENUMERABLE_ETH) || isPair(_msgSenderERC721A(), PairVariant.MISSING_ENUMERABLE_ERC20))
            return;
        
        require(false, 'Can only be swapped via SudoSwap');
    }

    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function isPair(address potentialPair, PairVariant variant) private view returns (bool)
    {
        if (variant == PairVariant.MISSING_ENUMERABLE_ERC20) {
            return
                LSSVMPairCloner.isERC20PairClone(
                    sudoswapFactory,
                    missingEnumerableERC20Template,
                    potentialPair
                );
        } else if (variant == PairVariant.MISSING_ENUMERABLE_ETH) {
            return
                LSSVMPairCloner.isETHPairClone(
                    sudoswapFactory,
                    missingEnumerableETHTemplate,
                    potentialPair
                );
        } else {
            // invalid input
            return false;
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

