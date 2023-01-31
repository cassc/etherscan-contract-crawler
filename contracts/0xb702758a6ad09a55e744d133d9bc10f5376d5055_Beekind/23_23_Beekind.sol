// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
 _______       .-''-.      .-''-.  .--.   .--. .-./`) ,---.   .--. ______      
\  ____  \   .'_ _   \   .'_ _   \ |  | _/  /  \ .-.')|    \  |  ||    _ `''.  
| |    \ |  / ( ` )   ' / ( ` )   '| (`' ) /   / `-' \|  ,  \ |  || _ | ) _  \ 
| |____/ / . (_ o _)  |. (_ o _)  ||(_ ()_)     `-'`"`|  |\_ \|  ||( ''_'  ) | 
|   _ _ '. |  (_,_)___||  (_,_)___|| (_,_)   __ .---. |  _( )_\  || . (_) `. | 
|  ( ' )  \'  \   .---.'  \   .---.|  |\ \  |  ||   | | (_ o _)  ||(_    ._) ' 
| (_{;}_) | \  `-'    / \  `-'    /|  | \ `'   /|   | |  (_,_)\  ||  (_.\.' /  
|  (_,_)  /  \       /   \       / |  |  \    / |   | |  |    |  ||       .'   
/_______.'    `'-..-'     `'-..-'  `--'   `'-'  '---' '--'    '--''-----'`     

*/                                                                               

import "../lib/ERC721A/contracts/ERC721A.sol";
import "../lib/ERC721A/contracts/IERC721A.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import { DefaultOperatorFilterer } from "../lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { IERC2981, ERC2981 } from "../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract Beekind is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer  {

    using ECDSA for bytes32;

    uint256 public MAX_SUPPLY = 5000;
    uint256 public COST = 0.0069 ether;

    uint256 publicAllocation = 2500;
    uint256 beelistAllocation = 500;
    uint256 publicMints = 0;
    uint256 beelistMints = 0;

    uint8 public saleState = 0;
    bool TRANSFER_TRACKING = true;
    bool public REVEALED = false;
    string public BASEURI;

    address private royaltyReceiver;

    address authorizedCaller;
    address publicSigner;
    address beelistSigner;

    mapping (uint256 => uint256) private transfers;
    mapping (bytes => bool) private usedSignatures;

    constructor(address _royaltyReceiver, address _beelistSigner) ERC721A("Beekind", "BKIND") {
        beelistSigner = _beelistSigner;
        royaltyReceiver = _royaltyReceiver;
        _setDefaultRoyalty(_royaltyReceiver, 690);
        _mint(_royaltyReceiver, 1);
    }

    function beelistbZzZz(bytes calldata _signature) external isMintable validSignature(_signature, publicSigner) {
        require(saleState == 2, "Beelist is not active.");
        require(beelistMints + 1 <= beelistAllocation, "Beelist allocation is full.");

        beelistMints++;
        usedSignatures[_signature] = true;
        _mint(msg.sender, 1);
    }

    function bZzZz(uint256 _num) external payable isMintable {
        require(saleState == 1, "Public sale not active.");
        require(_num <= 5, "Over 5 per transaction limit.");
        require(publicMints + _num <= publicAllocation, "Public allocation is full.");
        require(msg.value >= COST, "Insufficient value sent.");
        
        publicMints += _num;
        _mint(msg.sender, _num);
    }

    function honeymint(address _to) external onlyAuthorizedCaller isMintable {
        _mint(_to, 1);
    }

    function airDropTokens(address[] calldata _to) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            address current = _to[i];
            _mint(current, 1);
        }
    }

    modifier onlyAuthorizedCaller {
        require(msg.sender == authorizedCaller, "Unauthorized caller.");
        _;
    }
    
    modifier validSignature(bytes memory _signature, address _signer) {
        require(!usedSignatures[_signature], "This signature has already been used.");
        require(
            keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(_signature) == _signer,
            "Invalid signature"
        );
        _;
    }

    modifier isMintable {
        require(totalSupply() + 1 <= MAX_SUPPLY, "No more bees in the hive.");
        _;
    }

    function setCost(uint256 _cost) external onlyOwner {
        COST = _cost;
    }

    function setBaseURI(string calldata _baseMetadataURI) external onlyOwner {
        BASEURI = _baseMetadataURI;
    }

    function getMintableSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function setSaleState(uint8 _saleState) external onlyOwner {
        saleState = _saleState;
    }
    
    function reveal(bool _reveal) external onlyOwner {
        REVEALED = _reveal;
    }

    function toggleTransferTracking() external onlyOwner {
        TRANSFER_TRACKING = !TRANSFER_TRACKING;
    }

    function setAuthorizedCaller(address _caller) external onlyOwner {
        authorizedCaller = _caller;
    }

    function canShowToken(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId) && REVEALED;
    }

    function getTokenTransfers(uint256 _tokenId) external view returns (uint256) {
        return transfers[_tokenId];
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        if (!TRANSFER_TRACKING) return;
        if (to == address(0) || from == address(0)) return;
        if (to == authorizedCaller || from == authorizedCaller) return;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;
            transfers[tokenId]++;
        }

    }

    function _baseURI() internal override view virtual returns (string memory) {
        return BASEURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        payable(royaltyReceiver).transfer(address(this).balance);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable 
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}