//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./TreatsNFT.sol";

contract DogNFT is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;

    /**********
    DEV DEFINED
    ***********/
    mapping(address => uint256) public boostFee;
    mapping(uint256 => uint256) public tokenEvolution;
    mapping(uint256 => uint256) public tokenEvolved;

    uint256 _totalBoosts;
    uint256 _totalBoosters;
    address[] public boosters;

    string _baseUri = "https://awoo.finance/snctry/json/dogs/";

    TreatsNFT treatsNFT;

    constructor(
        TreatsNFT _treatsNft,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        treatsNFT = _treatsNft;
    }

    function setTreatsNFT(TreatsNFT _treatsNft) external onlyOwner {
        treatsNFT = _treatsNft;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseUri = _uri;
    }

    function contractURI() public pure returns (string memory) {
        return "https://awoo.finance/snctry/json/contractdog";
    }
  
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);

        if (boostFee[to] == 0) {
            _totalBoosters = _totalBoosters.add(1);
            boosters.push(to);
        }
        boostFee[to] = boostFee[to].add(10);
        _totalBoosts = _totalBoosts.add(10);

        uint256 randomEvolution = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        ).mod(100)
        .add(10)
        .div(10)
        .mul(10);

        tokenEvolution[tokenId] = randomEvolution;
    }

    function getRedistFeeOf(address _holder) public view returns (uint256) {
        return boostFee[_holder];
    }

    function totalBoosts() public view returns (uint256) {
        return _totalBoosts;
    }

    function totalBoosters() public view returns (uint256) {
        return _totalBoosters;
    }

    function feedDog(
        uint256 tokenId,
        uint256 treatTokenId,
        uint256 amount
    ) external {
        require(
            tokenEvolved[tokenId] < tokenEvolution[tokenId],
            "Already Evolved"
        );

        treatsNFT.burn(_msgSender(), treatTokenId, amount);

        tokenEvolved[tokenId] = tokenEvolved[tokenId].add(
            treatsNFT.evoPoint(treatTokenId).mul(amount)
        );

        if (tokenEvolved[tokenId] >= tokenEvolution[tokenId]) {
            address boosterAddr = ownerOf(tokenId);
            uint256 extraBoost = tokenEvolution[tokenId].div(10);
            boostFee[boosterAddr] = boostFee[boosterAddr].add(extraBoost);
            _totalBoosts = _totalBoosts.add(extraBoost);
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) return;

        uint256 tokenBoost = 10;
        if (tokenEvolved[tokenId] > tokenEvolution[tokenId]) {
            tokenBoost = tokenBoost.add(tokenEvolution[tokenId].div(10));
        }

        boostFee[from] = boostFee[from].sub(tokenBoost);
        if (boostFee[from] == 0) {
            for (uint256 i = 0; i < boosters.length; i = i.add(1)) {
                if (boosters[i] == from) {
                    boosters[i] = boosters[boosters.length - 1];
                    boosters.pop();
                    _totalBoosters = _totalBoosters.sub(1);
                    break;
                }
            }
        }

        boostFee[to] = boostFee[to].add(tokenBoost);
        if (boostFee[to] == tokenBoost) {
            boosters.push(to);
            _totalBoosters = _totalBoosters.add(1);
        }
    }
}