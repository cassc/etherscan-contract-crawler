// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ENS.sol";

// ███╗░░██╗██╗███████╗████████╗██╗░░░██╗██╗░░██╗██╗████████╗  ██╗░░░██╗██████╗░
// ████╗░██║██║██╔════╝╚══██╔══╝╚██╗░██╔╝██║░██╔╝██║╚══██╔══╝  ██║░░░██║╚════██╗
// ██╔██╗██║██║█████╗░░░░░██║░░░░╚████╔╝░█████═╝░██║░░░██║░░░  ╚██╗░██╔╝░░███╔═╝
// ██║╚████║██║██╔══╝░░░░░██║░░░░░╚██╔╝░░██╔═██╗░██║░░░██║░░░  ░╚████╔╝░██╔══╝░░
// ██║░╚███║██║██║░░░░░░░░██║░░░░░░██║░░░██║░╚██╗██║░░░██║░░░  ░░╚██╔╝░░███████╗
// ╚═╝░░╚══╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░░╚═╝░░░  ░░░╚═╝░░░╚══════╝
contract DropKitCollection is ERC721, ERC721Enumerable, Ownable {
    using Address for address;
    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    uint256 public immutable _maxAmount;
    uint256 public _maxPerMint;
    uint256 public _maxPerWallet;
    uint256 public _price;

    string internal _tokenBaseURI;
    bytes32 internal _merkleRoot;
    mapping(address => uint256) internal _mintCount;

    bool public started = false;
    uint256 public totalRevenue = 0;
    uint256 public niftyKitFees = 0;
    uint256 public feesClaimed = 0;

    uint256 private constant _commissionRate = 500; // parts per 10,000
    bytes32 private constant _niftyKit =
        0xc5d1114c6023fd78e89dca4228d59c42fde243eba4d98bb8798037216662dd21; // namehash

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxAmount,
        uint256 maxPerMint,
        uint256 maxPerWallet,
        uint256 price,
        string memory tokenBaseURI
    ) ERC721(name, symbol) {
        _maxAmount = maxAmount;
        _maxPerMint = maxPerMint;
        _maxPerWallet = maxPerWallet;
        _price = price;
        _tokenBaseURI = tokenBaseURI;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(started == true, "Sale must be active");
        require(numberOfTokens <= _maxPerMint, "Exceeded maximum per mint");
        require(numberOfTokens > 0, "Must mint greater than 0");
        require(
            _mintCount[_msgSender()] <= _maxPerWallet,
            "Exceeded maximum per wallet"
        );
        require(
            totalSupply().add(numberOfTokens) <= _maxAmount,
            "Exceeded max supply"
        );
        require(
            _price.mul(numberOfTokens) == msg.value,
            "Value sent is not correct"
        );
        niftyKitFees = niftyKitFees.add(commissionAmount(_price.mul(numberOfTokens)));
        totalRevenue = totalRevenue.add(msg.value);
        _mintCount[_msgSender()].add(numberOfTokens);
        _mint(numberOfTokens, _msgSender());
    }

    function presaleMint(uint256 numberOfTokens, bytes32[] calldata proof)
        public
        payable
    {
        require(_verify(_leaf(_msgSender()), proof), "Not part of list");
        require(numberOfTokens <= _maxPerMint, "Exceeded maximum per mint");
        require(numberOfTokens > 0, "Must mint greater than 0");
        require(
            _mintCount[_msgSender()] <= _maxPerWallet,
            "Exceeded maximum per wallet"
        );
        require(
            totalSupply().add(numberOfTokens) <= _maxAmount,
            "Exceeded max supply"
        );
        require(
            _price.mul(numberOfTokens) == msg.value,
            "Value sent is not correct"
        );

        niftyKitFees = niftyKitFees.add(commissionAmount(_price.mul(numberOfTokens)));
        totalRevenue = totalRevenue.add(msg.value);
        _mintCount[_msgSender()].add(numberOfTokens);
        _mint(numberOfTokens, _msgSender());
    }

    function airdrop(uint256 numberOfTokens, address recipient)
        public
        payable
        onlyOwner
    {
        require(
            totalSupply().add(numberOfTokens) <= _maxAmount,
            "Exceeded max supply"
        );
        require(
            commissionAmount(_price.mul(numberOfTokens)) == msg.value,
            "Value sent is not correct"
        );

        niftyKitFees = niftyKitFees.add(commissionAmount(_price.mul(numberOfTokens)));
        _mint(numberOfTokens, recipient);
    }

    function start() public onlyOwner {
        require(started == false, "Sale is already started");

        started = true;
    }

    function pause() public onlyOwner {
        require(started == true, "Sale is already paused");

        started = false;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function withdraw() public {
        require(address(this).balance > 0, "Nothing to withdraw");

        Resolver resolver = ens.resolver(_niftyKit);
        uint256 balance = address(this).balance;
        uint256 commission = niftyKitFees - feesClaimed;
        Address.sendValue(payable(owner()), balance - commission);
        Address.sendValue(payable(resolver.addr(_niftyKit)), commission);

        feesClaimed = feesClaimed.add(commission);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    function setParameters(
        uint256 maxPerMint,
        uint256 maxPerWallet,
        uint256 price
    ) public onlyOwner {
        _maxPerMint = maxPerMint;
        _maxPerWallet = maxPerWallet;
        _price = price;
    }

    function commissionAmount(uint256 amount) public pure returns (uint256) {
        return ((_commissionRate * amount) / 10000);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _mint(uint256 numberOfTokens, address sender) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(sender, mintIndex);
        }
    }

    function _leaf(address wallet) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(wallet));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}