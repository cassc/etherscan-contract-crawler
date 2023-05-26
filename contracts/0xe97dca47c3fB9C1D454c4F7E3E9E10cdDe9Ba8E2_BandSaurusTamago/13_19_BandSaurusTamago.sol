// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721psi/contracts/extension/ERC721PsiBurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/ITokenURI.sol";
import "./base64.sol";


contract BandSaurusTamago is ERC721PsiBurnable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    modifier onlyOperator() {
        require(_operators[msg.sender],'account is not an operator');
        _;
    }

    ITokenURI public tokenuri;
    uint256 public maxSupply = 1000000;
    uint256 public mintPrice = 10000000000000000; // 0.01Eth
    address public withdrawAddress;
    string public imageURI = "https://metadata.ctdao.io/bst/tamago.jpg";
    mapping(address => bool) _operators;

    constructor() ERC721Psi("BAND SAURUS TAMAGO", "BST") {
        withdrawAddress = msg.sender;
        _operators[msg.sender] = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "BandSaurusTamago: URI query for nonexistent token");

        if(address(tokenuri) == address(0)){
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "TAMAGO #', tokenId.toString() , '", "description": "","image": "', imageURI , '"}'))));
            return string(abi.encodePacked('data:application/json;base64,', json));
        }else{
            // Full-on chain support
            return tokenuri.tokenURI_future(tokenId);
        }
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function mint() external nonReentrant payable {
        require(msg.value >= mintPrice, "BandSaurusTamago: Invalid price");
        require(totalSupply() + 1 <= maxSupply  , 'BandSaurusTamago: can not mint, over max size');
        _safeMint(msg.sender, 1);
    }

    function batchMint(address[] calldata to) external nonReentrant onlyOperator{
        require(totalSupply() + to.length <= maxSupply  , 'BandSaurusTamago: can not mint, over max size');
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], 1);
        }
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function setTokenURI(ITokenURI tokenuri_) external onlyOwner {
        tokenuri = tokenuri_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setPrice(uint256 _priceInWei) external onlyOwner {
        mintPrice = _priceInWei;
    }

    function setWithdrawAddress(address _address) external onlyOwner {
        withdrawAddress = _address;
    }

    function setImageURI(string memory _value) external onlyOwner {
        imageURI = _value;
    }

    function withdraw() external onlyOwner {
        bool result;
        (result, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(result, "transfer failed");
    }

    function grantOperatorRole(address account) external onlyOwner {
        require(!_operators[account],'account is already has an operator role');
        _operators[account] = true;
    }

    function revokeOperatorRole(address account) external onlyOwner {
        require(_operators[account],'account is not an operator');
        delete _operators[account];
    }

    receive() external payable {}

}