// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract ARTECONFTUPGRADEABLE1155 is Initializable, ERC1155SupplyUpgradeable, ERC2981Upgradeable, OwnableUpgradeable {
    using Strings for uint256;
    using ECDSA for bytes32;
    /*
        variables
    */
    struct tokenStruct {
        string individualUri;
        string ipfsUri;
        uint256 priceInWei;
        uint128 projectId;
        uint128 maxAmount;
        bytes32[] metadatafileHashes;
    }
    struct projectStruct {
        uint128 arteconftPercentage;
        address artistAddress;
    }
    string private _name;
    string public baseUri;
    address public mintAccount;
    mapping(uint256 => tokenStruct) public tokenIdToToken;
    mapping(uint256 => projectStruct) public projectIdToProject;
    mapping(address => uint256) private withdrawal_AddressToAmount;


    function initialize() public initializer {
        _name = "ARTECONFT";
        __ERC1155_init("https://arteconft.com/metadata/");
        __Ownable_init();
    }

    /*
        functions
    */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function mintToAddress(uint256 tokenId, address _address, uint256 amount) external onlyOwner {
        require(tokenIdToToken[tokenId].maxAmount - totalSupply(tokenId) >= amount, "ARTECONFT: Minting more NFTs than possible");
        _mint(_address, tokenId, amount, "");
    }
    
    function mintBySignature(bytes memory signature, uint256 tokenId, uint256 amount) external payable {
        require(tokenIdToToken[tokenId].priceInWei > 0, "ARTECONFT: NFT has not been initialized");
        require(msg.value > tokenIdToToken[tokenId].priceInWei, "ARTECONFT: eth value too low for mint");
        require(tokenIdToToken[tokenId].maxAmount - totalSupply(tokenId) >= amount, "ARTECONFT: Minting more NFTs than possible");
        // create hash of address because toEthSignedMessageHash expects a hash
        bytes32 addrHash = keccak256(abi.encodePacked(msg.sender));
        // create eth_sign equivalent hash
        addrHash = ECDSA.toEthSignedMessageHash(addrHash);
        address recovered =  ECDSA.recover(addrHash, signature);
        require(recovered == mintAccount);
        uint arteconftShare = (msg.value * projectIdToProject[tokenIdToToken[tokenId].projectId].arteconftPercentage) / 100;
        withdrawal_AddressToAmount[this.owner()] += arteconftShare;
        withdrawal_AddressToAmount[projectIdToProject[tokenIdToToken[tokenId].projectId].artistAddress] += msg.value - arteconftShare;
        _mint(msg.sender, tokenId, amount, "");
    }
    function setMintAccount(address _mintAccount) external onlyOwner{
        mintAccount = _mintAccount;
    }
    function setProjectAddress(uint256 _projectId, address _projectAddress) external onlyOwner {
        projectIdToProject[_projectId].artistAddress = _projectAddress;
    }
    function setArteconftPercentage(uint256 _projectId, uint128 _arteconftPercentage) external onlyOwner {
        projectIdToProject[_projectId].arteconftPercentage = _arteconftPercentage;
    }
    function initializeNft(uint256 tokenId, uint256 _priceInWei, uint128 _projectId, uint128 _maxAmount, bytes32 _hash) external onlyOwner {
        tokenIdToToken[tokenId].priceInWei = _priceInWei;
        tokenIdToToken[tokenId].projectId = _projectId;
        tokenIdToToken[tokenId].maxAmount = _maxAmount;
        (tokenIdToToken[tokenId].metadatafileHashes).push(_hash);
    }
    function setDefaultRoyalty(uint96 defaultRoyaltyFractionInBps) external onlyOwner{
        _setDefaultRoyalty(msg.sender, defaultRoyaltyFractionInBps);
    }
    function setTokenRoyalty(uint256 tokenId, uint96 royaltyFractionInBps) external virtual onlyOwner {
        _setTokenRoyalty(tokenId, this.owner(), royaltyFractionInBps);
    }
    function appendHashes(uint256 tokenId, bytes32 _hash) external onlyOwner {
        (tokenIdToToken[tokenId].metadatafileHashes).push(_hash);
    }
    function getHashes(uint256 tokenId) external view returns (bytes32[] memory) {
        return tokenIdToToken[tokenId].metadatafileHashes;
    }
    function setIPFSUrl(uint256 tokenId, string memory _ipfsUri) external onlyOwner {
        tokenIdToToken[tokenId].ipfsUri = _ipfsUri;
    }
    function setIindividualUrl(uint256 tokenId, string memory _individualUri) external {
        require(totalSupply(tokenId) == 1 && balanceOf(msg.sender, tokenId) == 1, "ARTECONFT: Only NFT owner can set individual URI");
        tokenIdToToken[tokenId].individualUri = _individualUri;
    }
    function _setBaseURI(string memory _baseUri) external onlyOwner {
        _setURI(_baseUri);
    }
    function _setURI(string memory _baseUri) internal override {
        baseUri = _baseUri;
    }
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "ARTECONFT: URI query for nonexistent token");
        if (bytes(tokenIdToToken[tokenId].ipfsUri).length > 0) {
            return tokenIdToToken[tokenId].ipfsUri;
        } else {
            return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString())) : "";
        }
    }
    function getBalance(address _address) external view returns (uint256) {
        return withdrawal_AddressToAmount[_address];
    }

    //TODO
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdrawTo(address _address) external {
        uint256 withdrawalAmount = withdrawal_AddressToAmount[_address];
        require(withdrawalAmount > 0, "ARTECONFT: nothing to withdraw");
        withdrawal_AddressToAmount[_address] = 0;
        (bool success, ) = payable(_address).call{value: withdrawalAmount}("");
        require(success, "ARTECONFT: Failed to send Ether");
    }
}