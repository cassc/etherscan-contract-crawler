// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// ███████╗██╗░░░██╗███████╗███╗░░░███╗░█████╗░██████╗░  ░█████╗░░█████╗░░█████╗░██╗░░██╗██╗███████╗░██████╗
// ██╔════╝╚██╗░██╔╝██╔════╝████╗░████║██╔══██╗██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗██║░██╔╝██║██╔════╝██╔════╝
// █████╗░░░╚████╔╝░█████╗░░██╔████╔██║███████║██████╔╝  ██║░░╚═╝██║░░██║██║░░██║█████═╝░██║█████╗░░╚█████╗░
// ██╔══╝░░░░╚██╔╝░░██╔══╝░░██║╚██╔╝██║██╔══██║██╔═══╝░  ██║░░██╗██║░░██║██║░░██║██╔═██╗░██║██╔══╝░░░╚═══██╗
// ███████╗░░░██║░░░███████╗██║░╚═╝░██║██║░░██║██║░░░░░  ╚█████╔╝╚█████╔╝╚█████╔╝██║░╚██╗██║███████╗██████╔╝
// ╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░░░░  ░╚════╝░░╚════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚══════╝╚═════╝░

contract EyeMapCookies is Ownable, ReentrancyGuard {

    address public eyeverseContract;

    constructor(address _eyeverseContract) {
        eyeverseContract = _eyeverseContract;
        addArtist(0xF11157F3e05EEda1317FF628930637b6656D25B3);
        addArtist(0x76D690996B97af35E4F8FF115719afb96B98D21F);
        addArtist(0xf631F197fD1d178d404bc10CF91D25C3D7451FB8);
        addArtist(0x73d334635C803786FF91e13E58Cdea2D80471438);
    }

    uint[] public maxSupply = [100, 100, 100];
    uint[] public currentSupply = [0, 0, 0];
    uint[] public price = [0.025 ether, 0.05 ether, 0.1 ether];

    struct ArtRequest {
        uint256 cookieId;
        address from;
        uint256 eyeverseId;
    }

    mapping(address => ArtRequest[]) public requests;
    mapping(address => uint256) public artistCounter;
    mapping(uint256 => bool) public tokenClaimed;   

    bool public paused = false;

    // MODIFIERS
    
    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    // COOKIES ... and stuff!

    function claimToken(address artistAddy, uint256 cookieId, uint256 eyeverseId) public payable notPaused nonReentrant {

        require(artistCounter[artistAddy] > 0, "No Artist found");
        require(currentSupply[cookieId] + 1 <= maxSupply[cookieId], "Cookies sold out");

        IERC721 token = IERC721(eyeverseContract);
        require(msg.sender == token.ownerOf(eyeverseId), "Caller is not owner of token");
        require(tokenClaimed[eyeverseId] == false, "Token already requested");

        require(msg.value >= price[cookieId], "Insufficient funds");

        tokenClaimed[eyeverseId] = true;
        currentSupply[cookieId] += 1;

        artistCounter[artistAddy] += 1;

        requests[artistAddy].push(ArtRequest(cookieId, msg.sender, eyeverseId));
    }

    function claimTokenAdmin(address artistAddy, uint256 cookieId, uint256 eyeverseId) public notPaused nonReentrant onlyOwner {

        require(artistCounter[artistAddy] > 0, "No Artist found");
        require(currentSupply[cookieId] + 1 <= maxSupply[cookieId], "Cookies sold out");

        IERC721 token = IERC721(eyeverseContract);
        require(msg.sender == token.ownerOf(eyeverseId), "Caller is not owner of token");
        require(tokenClaimed[eyeverseId] == false, "Token already requested");

        tokenClaimed[eyeverseId] = true;
        currentSupply[cookieId] += 1;

        artistCounter[artistAddy] += 1;

        requests[artistAddy].push(ArtRequest(cookieId, msg.sender, eyeverseId));
    }

    // Defaults to 1
    function addArtist(address _artistAddress) public onlyOwner {
        artistCounter[_artistAddress] = 1;
    }

    // CRUD

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxSupply(uint[] calldata _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint[] calldata _price) public onlyOwner {
        price = _price;
    }

    // VIEW

    function getRequests(address _artist, uint256 requestId) public view returns (uint256, address, uint256) {
        require(requestId <= requests[_artist].length, "Invalid request ID");
        return (requests[_artist][requestId].cookieId, requests[_artist][requestId].from, requests[_artist][requestId].eyeverseId);
    }

    function getArtistActualRequestsCount(address _artist) public view returns (uint256) {
        return artistCounter[_artist] - 1;
    }

    // WITHDRAW

    function withdraw() public onlyOwner nonReentrant {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x43cDb4A408c1670F2A3C9B80e891CD63770CFCa7).call{value: ((balance * 100) / 100)}("");
        require(success, "Transaction Unsuccessful");
    }
}