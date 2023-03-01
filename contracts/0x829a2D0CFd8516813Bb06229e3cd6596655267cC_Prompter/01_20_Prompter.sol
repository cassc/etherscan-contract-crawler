// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// @creator: 0xmonas.eth
// @author: f

////////////////////////////
//                        //
//                        //
//          ████          //
//          ████          //
//          ████          //
//          ████          //
//          ████          //
//          ████          //
//                        //
//                        //
////////////////////////////

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";

contract Prompter is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    enum Status { Inactive, Private, Whitelist, Public }

    mapping (uint256 => string) private prompts;
    mapping (string => bool) public promptCheck;
    mapping (address => uint256) public promptCount;
    mapping (uint256 => uint256) public promptTimestamp;
    mapping (address => uint256) public whitelistCount;
    mapping (address => uint256) public privateCount;
    
    uint256 public constant price = 0.0069 ether;
    uint256 public constant wlPrice = 0.0042 ether;

    uint256 public constant maxPerWallet = 5;
    uint256 public constant maxPerWalletWL = 2;
    uint256 public constant maxPerWalletPrivate = 3;

    uint256 public constant maxSupply = 10000;
    uint256 public constant wlSupply = 1400;
    uint256 public constant privateSupply = 1260;
    uint256 public totalSupply;

    uint256 royaltyAmount;

    bytes32 private merkleRootWL;
    bytes32 private merkleRootPrivate;

    address public frac;
    address royalties_recipient;

    Status public saleStatus;

    error FundsInsufficient();
    error MerkleProofInvalid();
    error MintLimitReached();
    error PromptClaimed();
    error PromptInvalid();
    error SaleStatusInvalid();
    error SupplyLimitReached();
    
    constructor() ERC721("Prompter II", "TPC") {
        saleStatus = Status.Inactive;
        frac = 0x63e967a97407E66D12fE57155345bfA7992Ed6D6;
    }

    modifier checkRequirements(uint256 _minPrice, string calldata _prompt, uint256 _saleStatus, uint256 mintLimit, uint256 maxMintPerWallet, uint256 mintCount) {
        if(bytes(_prompt).length > 420) revert PromptInvalid();
        if(promptCheck[_prompt] == true) revert PromptClaimed();
        if(msg.value < _minPrice) revert FundsInsufficient();
        if(uint256(saleStatus) != _saleStatus) revert SaleStatusInvalid();
        if(totalSupply >= mintLimit) revert SupplyLimitReached();
        if(mintCount >= maxMintPerWallet) revert MintLimitReached();
        _;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        ERC721.supportsInterface(interfaceId) ||
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mint(string calldata _prompt) public payable checkRequirements(price, _prompt, 3, maxSupply, maxPerWallet, promptCount[msg.sender]) {
        claimPrompt(_prompt, block.timestamp);
    }

    function mintWL(string calldata _prompt, bytes32[] calldata _merkleProof) public payable checkRequirements(wlPrice, _prompt, 2, (privateSupply + wlSupply), maxPerWalletWL, whitelistCount[msg.sender]){
        if(!MerkleProof.verify(_merkleProof, merkleRootWL, keccak256(abi.encodePacked(msg.sender)))) revert MerkleProofInvalid();

        whitelistCount[msg.sender]++;
        claimPrompt(_prompt, block.timestamp);
    }

    function mintPrivate(string calldata _prompt, bytes32[] calldata _merkleProof) public payable checkRequirements(0, _prompt, 1, privateSupply, maxPerWalletPrivate, privateCount[msg.sender]){
        if(!MerkleProof.verify(_merkleProof, merkleRootPrivate, keccak256(abi.encodePacked(msg.sender)))) revert MerkleProofInvalid();

        privateCount[msg.sender]++;
        claimPrompt(_prompt, block.timestamp);
    }

    function claimPrompt(string memory _prompt, uint256 _timestamp) internal {
        totalSupply++;
        promptCheck[_prompt] = true;
        prompts[totalSupply] = _prompt;
        promptCount[msg.sender]++;
        promptTimestamp[totalSupply] = _timestamp;

        _safeMint(msg.sender, totalSupply);
    }

    function adminMint(string calldata _prompt) public onlyOwner {
        claimPrompt(_prompt, block.timestamp);
    }

    function buildImage(string memory _prompt) internal pure returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="1000" height="1000" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    '<rect height="100%" width="100%" y="0" x="0" fill="#f5f5f5"/>',
                    '<defs>',
                    '<path id="path1" d="M29.43,81.73H970.93M29.43,147.1H970.93M28.93,212.5H970.41M29.21,277.82H970.69M29.21,343.17H970.69M29.21,408.55H970.69M28.7,473.91H970.18M29.8,539.26H971.3M29.8,604.64H971.3M29.31,670.04H970.77M29.59,735.35H971.07M29.59,800.71H971.07M29.59,866.09H971.07M29.07,931.44H970.53"></path>',
                    '</defs>',
                    '<use xlink:href="#path1" />',
                    '<text font-size="50.50px" fill="#0c0c0c" font-family="Courier New" font-variant="normal" font-weight="bold">',
                    '<textPath xlink:href="#path1">', _prompt,'</textPath></text>',
                    '</svg>'
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return
            string(
                string.concat(
                    "data:application/json;base64,",
                    string(
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"', abi.encodePacked("P #", _tokenId.toString()),'",','"description":"Prompter is a collection by You and Monas.",','"image":"data:image/svg+xml;base64,', buildImage(prompts[_tokenId]), '",','"attributes": [{"trait_type": "Timestamp", "value": "', promptTimestamp[_tokenId].toString() ,'"}, {"trait_type": "Length", "value": "', bytes(prompts[_tokenId]).length.toString() ,'"}]}'
                            )
                        )
                    )
                )
            );
    }
    
    function setSaleStatus(Status _status) public onlyOwner {
        saleStatus = _status;
    }

    function setMerkleRoot(bytes32 _rootWL, bytes32 _rootPrivate) public onlyOwner {
        merkleRootWL = _rootWL;
        merkleRootPrivate = _rootPrivate;
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external onlyOwner {
        royalties_recipient = _recipient;
        royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(royalties_recipient != address(0)){
            return (royalties_recipient, (salePrice * royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance/2);
        payable(frac).transfer(address(this).balance);
    }
}