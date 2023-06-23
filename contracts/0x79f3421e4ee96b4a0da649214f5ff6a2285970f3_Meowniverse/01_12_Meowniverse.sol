//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract Meowniverse is ERC721A {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_MINT_PER_TX = 2;
    uint256 public constant MAX_PER_WHITELISTED = 2;
    uint256 public price = 0 ether;
    address public immutable owner;
    bytes32 private merkleRoot;
    Stage public stage;
    string public baseURI;
    string internal baseExtension = ".json";
    mapping(uint256 => uint256) private claimedBitMap;

    enum Stage {
        Whitelisted,
        Public,
        Pause
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Meowniverse: not owner");
        _;
    }

    event StageChanged(Stage from, Stage to);

    constructor() ERC721A("Meowniverse", "MNV") {
        owner = _msgSender();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Meowniverse: not exist");
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : ""
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setStage(Stage _stage) external onlyOwner {
        require(stage != _stage, "Meowniverse: invalid stage.");
        Stage prevStage = stage;
        stage = _stage;
        emit StageChanged(prevStage, stage);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(
        uint256 _index,
        uint256 _quantity,
        address _account,
        bytes32[] calldata _proofs
    ) external payable {
        _beforeMint(_index, _quantity, _account, _proofs);
        _safeMint(_account, _quantity);
    }

    function mintUnsold(uint256 _quantity) external onlyOwner {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "Meowniverse: exceed max supply"
        );
        _safeMint(msg.sender, _quantity);
    }

    function _beforeMint(
        uint256 _index,
        uint256 _quantity,
        address _account,
        bytes32[] calldata _proofs
    ) internal {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "Meowniverse: exceed max supply."
        );
        require(
            msg.value >= price * _quantity,
            "Meowniverse: insufficient fund."
        );
        if (stage == Stage.Whitelisted) {
            // Verify the merkle proof.
            bytes32 leaf = keccak256(abi.encodePacked(_index, _account));
            require(
                MerkleProof.verify(_proofs, merkleRoot, leaf),
                "Meowniverse: invalid proof."
            );

            _setClaimed(_index, _quantity);
        } else if (stage == Stage.Public) {
            require(
                _quantity <= MAX_MINT_PER_TX,
                "Meowniverse: too many mint."
            );
        } else {
            revert("Meowniverse: mint is pause.");
        }
    }

    function _setClaimed(uint256 index, uint256 quantity) internal {
        uint256 claimedWordIndex = (index * MAX_PER_WHITELISTED) /
            (256 / MAX_PER_WHITELISTED);
        uint256 claimedBitIndex = (index * MAX_PER_WHITELISTED) %
            (256 / MAX_PER_WHITELISTED);
        uint256 mask = ((2**MAX_PER_WHITELISTED - 1) << claimedBitIndex);
        uint256 bit = claimedBitMap[claimedWordIndex] & mask;
        uint256 prevClaimed = getQuantityFromBit(bit, claimedBitIndex);
        uint256 quantityBit = getBitFromQuantity(quantity) <<
            (prevClaimed + claimedBitIndex);
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            quantityBit;
        require(
            prevClaimed + quantity <= MAX_PER_WHITELISTED,
            "Meowniverse: limit reach."
        );
    }

    function getQuantityFromBit(uint256 bit, uint256 claimedBitIndex)
        internal
        pure
        returns (uint256)
    {
        if (bit == 0) {
            return 0;
        }

        for (
            uint256 i = claimedBitIndex;
            i <= claimedBitIndex + MAX_PER_WHITELISTED;
            i++
        ) {
            if (bit == 2**i - 2**claimedBitIndex) {
                return i - claimedBitIndex;
            }
        }

        return MAX_PER_WHITELISTED + 1;
    }

    function getBitFromQuantity(uint256 quantity)
        internal
        pure
        returns (uint256)
    {
        return (2**quantity) - 1;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        _withdraw(msg.sender, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}