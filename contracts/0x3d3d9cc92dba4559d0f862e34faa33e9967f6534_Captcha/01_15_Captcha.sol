// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BytesLib.sol";

contract Captcha is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
	using BytesLib for bytes;

    constructor() ERC721("CAPTCHAS", "CAPTCHA") {
        published = false;
        setBaseURI("https://api.thecaptcha.art/metadata/");
        setBaseCaptchaURI("https://api.thecaptcha.art/metadata/");
    }

    struct TokenMetadata {
        string name;
        address creator;
    }

    event Published();
    event Mint(uint256 indexed tokenId, string name, address indexed to);

    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant MAX_SUPPLY = 10000;

    bool public published;
    string public scriptJson;
    bytes public solvedCaptchaBytes;
    
    mapping (uint256 => TokenMetadata) public tokenIdToMetadata;

    // There is a base captcha URI so that the captcha can be fetched
    // before the token is minted, but it is the same as the regular URI
    string private _uriPrefix;
    string private _captchaUriPrefix;

    // The hashes must be created outside of the contract and fed in. 
    // Creating them within the contract would leak the solutions 
    bytes private _captchaHashes;

    function publish() public onlyOwner {
        require(published == false, "Already Published");
        published = true;
        emit Published();
    }

    // hashes are added as a single bytes string to save storage costs. Every two bytes represent 
    // the hash for the token at that respective index
    function setCaptchaHashes(bytes calldata hashes) external onlyOwner {
        _captchaHashes = hashes;
    }

    // To make it easier to read which captchas have already been solved, a single bytes
    // string is stored with each byte representing a boolean of whether the token has been minted or not
    // boolean bit packing is possible to reduce storage here but would make it more difficult to read all values at once
    function setSolvedCaptchas(bytes calldata solves) external onlyOwner {
        require(published == false, "Cannot Set After Published");
        solvedCaptchaBytes = solves;
    }

    // All information needed to recreate Captcha is stored on chain. Script is Node.js that draws
    // using Node Canvas instead of the browser Canvas in the event of breaking API changes to the browser Canvas
    function setGeneratorScript(string memory script) public onlyOwner {
        scriptJson = script;
    }

    function setBaseURI(string memory prefix) public onlyOwner {
        _uriPrefix = prefix;
    }

    function setBaseCaptchaURI(string memory prefix) public onlyOwner {
        _captchaUriPrefix = prefix;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _uriPrefix;
    }

    function _verifyCaptcha(uint256 tokenId, string memory captcha) internal view virtual returns (bool) {
        
        // prefix is only first four characters (2 bytes) for the sake of storage costs. Potential hash 
        // collisions are not particularly important in this use case. It could easily be increased if needed
        bytes memory passedInHashPrefix = abi.encodePacked(keccak256(bytes(captcha))).slice(0, 2);
        
        // start offset based on token ID as index
        uint256 start = tokenId * 2;
        
        bytes memory correctHashPrefix = bytes.concat(_captchaHashes[start], _captchaHashes[start + 1]);
        
        return passedInHashPrefix.equal(correctHashPrefix);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_uriPrefix, "contract"));
    }

    function tokenCaptchaURI(uint256 tokenId) public view virtual returns (string memory)  {
        string memory baseURI = _captchaUriPrefix;
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
    
    function getSolvedCaptchas() public view virtual returns (bytes memory)  {
        return solvedCaptchaBytes;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function mintCaptcha(uint256 tokenId, string memory solution) public nonReentrant payable {
        require(!_exists(tokenId), "Captcha Already Solved");
        require(_verifyCaptcha(tokenId, solution), "Incorrect Captcha");
        require(totalSupply() < MAX_SUPPLY, "Max Minted");
        require(msg.value == PRICE, "Wrong Eth Amount");
        require(published == true, "Not Published");

        TokenMetadata memory metadata;
        metadata.name = solution;
        metadata.creator = msg.sender;

        _safeMint(msg.sender, tokenId);

        tokenIdToMetadata[tokenId] = metadata;
        
        // set this token id as solved
        solvedCaptchaBytes[tokenId] = hex"01";

        emit Mint(tokenId, solution, msg.sender);
    }
}