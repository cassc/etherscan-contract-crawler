// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KMCSelect is ERC1155PresetMinterPauser {
    using Strings for uint256;

    enum TicketID {
        Normal,
        Rare,
        SuperRare
    }

    TicketID public mintPhase = TicketID.Normal;
    bool public mintable = false;
    string private _baseURI = "ar://nnXgxVTwutWgJg7KaRDLwUsjiGrF33vVs6CTNFvSGR0/";

    string constant public name = "KMCSelect";
    string constant public symbol = "KMCS";
    string constant private BASE_URI_SUFFIX = ".json";

    bytes32 public merkleRoot;
    mapping(address => uint256) private whiteListClaimed;

    constructor(
    ) ERC1155PresetMinterPauser("") {
       grantRole(MINTER_ROLE, msg.sender);
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    function preMint(uint256 _mintAmount,uint256 _presaleMax,bytes32[] calldata _merkleProof)
        public
        whenNotPaused
        whenMintable
    {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(
            whiteListClaimed[msg.sender] + _mintAmount <= _presaleMax,
            "Already claimed max"
        );

        _mint(msg.sender, uint(mintPhase), _mintAmount, "");
        whiteListClaimed[msg.sender] += _mintAmount ;
    }

    function setMintable(bool _state) public onlyRole(MINTER_ROLE) {
        mintable = _state;
    }

    function setMintPhase(TicketID _id) public onlyRole(MINTER_ROLE) {
        mintPhase = _id;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(MINTER_ROLE) {
       _baseURI = _newBaseURI;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(MINTER_ROLE) {
        merkleRoot = _merkleRoot;
    }


    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

     function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(
            _baseURI,
            Strings.toString(_id),
            BASE_URI_SUFFIX
        ));
    }

    function AdminBurn(
        address account,
        uint256 id,
        uint256 value
    ) public onlyRole(MINTER_ROLE) {
        _burn(account, id, value);
    }
}