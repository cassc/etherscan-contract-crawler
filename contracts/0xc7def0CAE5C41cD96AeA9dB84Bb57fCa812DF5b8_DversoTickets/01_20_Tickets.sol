// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./RevokableDefaultOperatorFilterer.sol";


interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
/// @custom:security-contact [email protected]
contract DversoTickets is ERC1155, Ownable, ERC1155Supply , Pausable, ERC1155Burnable , ERC2981Base , RevokableDefaultOperatorFilterer {

    address private signerAddress = 0x5211063C82D0CD0aB516a063206D50AA919eac75;
    using ECDSA for bytes32;

    mapping(uint256 => bool) public tokenEnabled;
    mapping(uint256 => bool) public tokenWhitelist;
    mapping(uint256 => uint256) public maxTokenPW;
    mapping(uint256 => uint256) public costs;
    mapping(uint256 => uint256) public tokenSupplies;
    mapping(uint256 => mapping(address => uint256)) private mintedBalances;
    mapping(uint256 => string) public cids;
    RoyaltyInfo private _royalties;

    constructor() ERC1155("") {
        _setRoyalties(0x5211063C82D0CD0aB516a063206D50AA919eac75 , 250);

        setTokenIndex(  1, //token Id
                        1, //max per wallet
                        2500, // supply
                        true, // whitelist verification enabled
                        true, // token enabled
                        "QmVVKSWDjZrDL9qrtC7CC6NuguJjswJnGwcmk35mQiGYSo", //cid
                        0 ether); // cost
    }

    function owner() public view virtual override (Ownable, RevokableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function setTokenIndex(uint256 tokenId,uint256 maxPerWallet,uint256 supply,bool whitelist,bool _enabled,string memory cid,uint256 cost) public onlyOwner {
        maxTokenPW[tokenId] = maxPerWallet;
        tokenEnabled[tokenId] = _enabled;
        tokenWhitelist[tokenId] = whitelist;
        tokenSupplies[tokenId] = supply;
        cids[tokenId] = cid;
        costs[tokenId] = cost;
    }

    function contractURI() public pure returns (string memory) {
        return "https://dverso.io/contract.json";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    
    function _baseURI(uint256 tokenId) internal view virtual returns (string memory) {
        return string(abi.encodePacked("ipfs://", cids[tokenId]));
    }

    function verifyAddressSigner(bytes calldata signature,uint256 tokenId) internal view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender,"#",Strings.toString(tokenId)));
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function mintedBalanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return mintedBalances[id][account];
    }
    
    function mint(bytes calldata signature, uint256 id, bytes memory data) public payable
    {
        if (tokenWhitelist[id]){
            require(verifyAddressSigner(signature,id), "SIGNATURE_VALIDATION_FAILED");
        }
        require(tokenSupplies[id] > 0, "Token is not mintable");
        require(tokenEnabled[id], "Token is not mintable");
        require(mintedBalanceOf(msg.sender,id) < maxTokenPW[id], "Reached max mint for token");
        require(totalSupply(id) < tokenSupplies[id], "Reached max supply");
        require(msg.value >= costs[id], "Value should not be lower than than cost");

        mintedBalances[id][msg.sender] += 1;
        _mint(msg.sender, id, 1, data);
    }
    
    function mintOwner(address account,uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        require(totalSupply(id) + (amount - 1) < tokenSupplies[id], "Reached max supply");
        require(tokenEnabled[id], "Token is not mintable");

        _mint(account, id, amount, data);
    }
    
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        
        for (uint256 i = 0; i < ids.length; i++) {
            require(totalSupply(ids[i]) + (amounts[i] - 1) < tokenSupplies[ids[i]], "Reached max supply");
            require(tokenEnabled[ids[i]], "Token is not mintable");
        }

        _mintBatch(to, ids, amounts, data);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint _id) public override view returns (string memory) {
        return string(abi.encodePacked(
            _baseURI(_id), "/", Strings.toString(_id),".json"
        ));
    }

    //set our royalties
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    //returns our royalties preferences
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
    
    //test if this contract support the interfaces for erc1155 and 2981
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // In case someone send money to the contract by mistake
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}