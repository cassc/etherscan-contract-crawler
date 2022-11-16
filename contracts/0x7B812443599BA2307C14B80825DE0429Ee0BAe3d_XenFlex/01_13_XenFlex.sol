// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IXENCrypto {
    // INTERNAL TYPE TO DESCRIBE A XEN MINT INFO
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    //get user Mints
    function userMints(address user) external view returns (MintInfo memory);
}

contract XenFlex is ERC721, ERC721Enumerable, Ownable {
    constructor() ERC721("XENFLEX", "XENFX") {}

    //Xen Contract Address
    address public constant XenContractAddress =
        0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;
    // Base URI
    string private _baseURL =
        "https://xenflex.blob.core.windows.net/nft-metadata/";

    /**
     * @dev This is the Minting NFT Functions_setBaseURI}.
     * Requires User to have an active Mint on Xen
     * Mints nft with the index of the Users current cRank
     */

    function mintNft() public {
        // Require User To have a active CRank
        require(getUserCRank() > 0, "XEN: You do not have a cRank");
        _safeMint(msg.sender, getUserCRank());
    }

    // The following functions are for setting and viewing the baseURI

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */

    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory bURI) public onlyOwner {
        _setBaseURI(bURI);
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */

    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURL = baseURI_;
    }

    // The following functions get any users Xen minting info

    function getAddressInfo(address userAddress)
        public
        view
        returns (IXENCrypto.MintInfo memory)
    {
        IXENCrypto.MintInfo memory _userInfo = IXENCrypto(XenContractAddress)
            .userMints(userAddress);
        return _userInfo;
    }

    // The following functions get the current users Xen minting info

    function getUserInfo() public view returns (IXENCrypto.MintInfo memory) {
        IXENCrypto.MintInfo memory _userInfo = IXENCrypto(XenContractAddress)
            .userMints(msg.sender);
        return _userInfo;
    }

    // Get the users Current CRank

    function getUserCRank() public view returns (uint256) {
        IXENCrypto.MintInfo memory _userInfo = IXENCrypto(XenContractAddress)
            .userMints(msg.sender);
        uint256 userCrank = _userInfo.rank;
        return userCrank;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}