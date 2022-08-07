//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { Verifier } from "./Verifier.sol";

contract Puzzle is Ownable, Pausable, ERC721, ERC721URIStorage, Verifier {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // mapping of all addresses that already hold the NFT
    mapping(address => bool) private _hackers;

    uint256 private constant 
        SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 private constant ENTRY_LIMIT = 12;
    string public baseURI;
    uint256 public refundingGasPrice; 

    // events
    event Solved(address indexed _solver, uint256 _nftID);
    event GasRefundSet(uint256 oldRefundPrice, uint256 newRefundPrice);

    constructor(string memory _uri, uint256 _refundingGasPrice) ERC721("GrothHacker", "GH") {
        setBaseURI(_uri);
        refundingGasPrice = _refundingGasPrice;
    }

    // ZK
    function solve(
        uint256[8] calldata _proof
    ) 
        external 
        refundGas
        whenNotPaused
    {
        require(
            !_hackers[msg.sender], 
            "Puzzle: you already have the NFT!"
        );

        require(
            areAllValidFieldElements(_proof),
            "Puzzle: invalid field element(s) in proof"
        );

        uint256 _a = uint256(uint160(address(msg.sender)));

        require(
            verifyProof(
                [_proof[0], _proof[1]],
                [[_proof[2], _proof[3]], [_proof[4], _proof[5]]],
                [_proof[6], _proof[7]],
                [_a]
            ),
            "Puzzle: Invalid proof"
        );

        // Mint the prize token
        mintToken(msg.sender);

        _hackers[msg.sender] = true;    
        emit Solved(msg.sender, _tokenIds.current() - 1);
    }

    function areAllValidFieldElements(
        uint256[8] memory _proof
    ) private pure returns (bool) {
        return 
            _proof[0] < SNARK_SCALAR_FIELD &&
            _proof[1] < SNARK_SCALAR_FIELD &&
            _proof[2] < SNARK_SCALAR_FIELD &&
            _proof[3] < SNARK_SCALAR_FIELD &&
            _proof[4] < SNARK_SCALAR_FIELD &&
            _proof[5] < SNARK_SCALAR_FIELD &&
            _proof[6] < SNARK_SCALAR_FIELD &&
            _proof[7] < SNARK_SCALAR_FIELD;
    }

    // NFT
    function mintToken(address owner)
        private
    {
        uint256 id = _tokenIds.current();
        require(id < ENTRY_LIMIT, "Puzzle: Too late!");
        _tokenIds.increment();
        _safeMint(owner, id);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri)
        public
        onlyOwner
    {
        baseURI = uri;
    }

    // All tokens are the same so just return the baseURI
    function tokenURI(uint256)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return _baseURI();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        require(from == address(0), "Token is not transferable");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// Pausable 
    function pause()
        public
        onlyOwner
        whenNotPaused
    {
        super._pause();
    }

    function unpause()
        public
        onlyOwner
        whenPaused
    {
        super._unpause();
    }

    /// Contract state
    receive() external payable {}

    function setRefundingGasPrice(uint256 _refundingGasPrice)
        external
        onlyOwner
    {
        uint256 oldRefundingGasPrice = refundingGasPrice;
        refundingGasPrice = _refundingGasPrice;
        emit GasRefundSet(oldRefundingGasPrice, refundingGasPrice);
    }

    function withdraw()
        external 
        onlyOwner
    {
        address payable sender = payable(msg.sender);
        sender.transfer(address(this).balance);
    }

    // Perform the gas refund
    // 28521 was estimated using Remix
    modifier refundGas() {
        uint256 gasBefore = gasleft();
         _;
        uint256 gasSpent = gasBefore - gasleft() + 28521;
        address payable sender = payable(msg.sender);

        uint gaspice = tx.gasprice < refundingGasPrice ? tx.gasprice : refundingGasPrice;
        sender.transfer(gasSpent * gaspice);
    }
}