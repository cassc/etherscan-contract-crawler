// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/YugaVerifyV3.sol";

contract BoredOhmsSewerApes is ERC721, YugaVerifyV3, Ownable {
    using Strings for uint256;

    address public constant BAYC  = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public constant w1     = 0x3bbCf2972299E6Da5eF830aF78791E3a7ed7278D;
    address public constant w2     = 0xd4E9486E81a73c56BAEeBF1455E114d854DFe7Ff;

    string  public baseURI;
    bool    public mintEnabled     = false;
    uint256 public maxSupply       = 10000;
    uint256 public price           = 0.003 ether;
    uint256 private _totalSupply;

    mapping(uint256 => bool) public minted;

    error MintNotLive();
    error NotEnoughETH();
    error NoneLeft();
    error NotValidToken();
    error TokenAlreadyMinted();
    error TokenDoesNotExist();
    error NotApprovedOrOwner();
    error WithdrawalFailed();

    constructor() ERC721("Bored Ohms Sewer Apes", "BOSA") YugaVerifyV3(0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c, 0x00000000000076A84feF008CDAbe6409d2FE638B){}

    function mint(uint256[] calldata tokenIds) external payable {
        if (!mintEnabled) {
            revert MintNotLive();
        }

        uint256 numTokens = tokenIds.length;
        if (msg.value < price * numTokens) {
            revert NotEnoughETH();
        }
        if (totalSupply() + numTokens > maxSupply) {
            revert NoneLeft();
        }

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenIds[i];
            _tryMint(tokenId);
        }
    }

    function _tryMint(uint256 tokenId) internal {
        if (tokenId >= maxSupply) {
            revert NotValidToken();
        }
        if (minted[tokenId]) {
            revert TokenAlreadyMinted();
        }

        bool isVerified = verifyTokenOwner(
            BAYC,
            tokenId
        );
        if (!isVerified) {
            revert NotApprovedOrOwner();
        }

        minted[tokenId] = true;
        _mint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(uint256 tokenId, address to) external onlyOwner {
        if (totalSupply() + 1 > maxSupply) {
            revert NoneLeft();
        }
        if (tokenId >= maxSupply) {
            revert NotValidToken();
        }
        if (minted[tokenId]) {
            revert TokenAlreadyMinted();
        }
        bool isVerified = verifyAirdropOwner(
            BAYC,
            tokenId,
            to
        );
        if (!isVerified) {
            revert NotApprovedOrOwner();
        }

        minted[tokenId] = true;
        _mint(to, tokenId);
    }

    function setBaseUri(string memory _baseuri) public onlyOwner {
        baseURI = _baseuri;
    }

    function setPrice(uint256 price_) external onlyOwner {
      price = price_;
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance <= 0) {
            revert NotEnoughETH();
        }
        _withdraw(w1, ((balance * 60) / 100));
        _withdraw(w2, ((balance * 40) / 100));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }
}