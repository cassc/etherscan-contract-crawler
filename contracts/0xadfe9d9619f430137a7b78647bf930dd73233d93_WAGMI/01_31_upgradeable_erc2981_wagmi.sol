// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./stringutils.sol";
import "./upgradeablefilter/DefaultOperatorFiltererUpgradeable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract WAGMI is Initializable, UUPSUpgradeable,  ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, ERC2981Upgradeable, DefaultOperatorFiltererUpgradeable {
    using Strings for uint256;

    uint256 private currentIndex;
    uint32 public maxSupply;
    string private _baseURIextended;
    string public baseExtension;

    mapping(address => uint256[]) private tokenIdsByAddress;

    //events
    event ERC20TokensRemoved(address indexed tokenAddress, address indexed receiver, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("WAGMI", "WAGMI");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        maxSupply = 3022;
        baseExtension = ".json";
        currentIndex = 0;
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable,ERC721URIStorageUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function claimNfts(address to) external {
        require(tokenIdsByAddress[to].length > 0, "No token IDs associated with the address");
        
        uint256[] memory tokenIds = tokenIdsByAddress[to];
        uint length = tokenIds.length;

        require(currentIndex + length <= maxSupply, "All NFTs Claimed");

        for (uint i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            // Call the mint function of your ERC721 token contract here
            _safeMint(to, tokenId);
            currentIndex++;
        }
    }

     // Set royalties info.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // set token url info
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            string(
                abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension)
            );
    }


    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _burn(uint256 id) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(id);
    }

    function addTokenIds(address user, uint256[] memory tokenIds) external onlyOwner {
        uint256[] storage userTokenIds = tokenIdsByAddress[user];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            userTokenIds.push(tokenIds[i]);
            
        }
    }

    function getTokenIds(address user) external view returns (uint256[] memory) {
        return tokenIdsByAddress[user];
    }

    function totalSupply() public view returns (uint256){
        return currentIndex;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override{}

       /// ============ OPERATOR FILTER REGISTRY ============
    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721Upgradeable, IERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

     /**
     * @notice withdraw accidently sent ERC20 tokens
     * @param _tokenAddress address of token to withdraw
     */
    function removeERC20Tokens(address _tokenAddress) external onlyOwner() {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, balance);
        emit ERC20TokensRemoved(_tokenAddress, msg.sender, balance);
    }

}