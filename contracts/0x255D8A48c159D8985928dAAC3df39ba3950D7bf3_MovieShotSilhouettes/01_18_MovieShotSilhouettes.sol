// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./AbstractERC1155Factory.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//   ███    ███  ██████  ██    ██ ██ ███████ ███████ ██   ██  ██████  ████████ ███████   //
//   ████  ████ ██    ██ ██    ██ ██ ██      ██      ██   ██ ██    ██    ██    ██        //
//   ██ ████ ██ ██    ██ ██    ██ ██ █████   ███████ ███████ ██    ██    ██    ███████   //
//   ██  ██  ██ ██    ██  ██  ██  ██ ██           ██ ██   ██ ██    ██    ██         ██   //
//   ██      ██  ██████    ████   ██ ███████ ███████ ██   ██  ██████     ██    ███████   //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////

contract MovieShotSilhouettes is AbstractERC1155Factory {
    using Counters for Counters.Counter;

    address public adminMinter;
    address public beneficiaryAddress;
    mapping(uint256 => Silhouette) public silhouettes;

    Counters.Counter private _counter;

    modifier onlyAdminMinter() {
        require(adminMinter == msg.sender, "Caller is not the admin minter");
        _;
    }

    event Claimed(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    event Minted(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    struct Silhouette {
        uint256 mintPrice;
        uint256 maxMintTx;
        uint256 maxSupply;
        string metadataHash;
        bytes32 merkleRoot;
        bool claimActive;
        bool mintActive;
        uint256 maxMint;
        mapping(address => uint256) minted;
        mapping(address => uint256) claimed;
    }

    constructor(
        string memory uri_,
        string memory baseExtension_,
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint256 royaltyShare_,
        address owner_,
        address adminMinter_,
        address beneficiaryAddress_
    )
        AbstractERC1155Factory(
            uri_,
            baseExtension_,
            name_,
            symbol_,
            royaltyReceiver_,
            royaltyShare_
        )
    {
        transferOwnership(owner_);
        adminMinter = adminMinter_;
        beneficiaryAddress = beneficiaryAddress_;
    }

    function addSilhouette(
        uint256 _mintPrice,
        uint256 _maxMintTx,
        uint256 _maxSupply,
        string memory _metadataHash,
        bytes32 _merkleRoot,
        uint256 _maxMint
    ) external onlyOwner {
        Silhouette storage s = silhouettes[_counter.current()];
        s.mintPrice = _mintPrice;
        s.maxMintTx = _maxMintTx;
        s.maxSupply = _maxSupply;
        s.metadataHash = _metadataHash;
        s.merkleRoot = _merkleRoot;
        s.maxMint = _maxMint;
        s.claimActive = false;
        s.mintActive = false;
        _counter.increment();
    }

    function editSilhouette(
        uint256 _id,
        uint256 _mintPrice,
        uint256 _maxMintTx,
        uint256 _decreaseMaxSupplyByAmount,
        string memory _metadataHash,
        bytes32 _merkleRoot,
        uint256 _maxMint
    ) external onlyOwner {
        require(silhouettes[_id].maxSupply > 0, "Silhouette does not exist");
        require(
            (silhouettes[_id].maxSupply - _decreaseMaxSupplyByAmount) >=
                totalSupply(_id),
            "Amount cannot be decreased as it has already been minted"
        );

        silhouettes[_id].maxMintTx = _maxMintTx;
        silhouettes[_id].mintPrice = _mintPrice;
        silhouettes[_id].maxSupply =
            silhouettes[_id].maxSupply -
            _decreaseMaxSupplyByAmount;
        silhouettes[_id].metadataHash = _metadataHash;
        silhouettes[_id].merkleRoot = _merkleRoot;
        silhouettes[_id].maxMint = _maxMint;
    }

    function editSilhouetteClaim(uint256[] calldata _ids, bool _claimActive)
        external
        onlyOwner
    {
        for (uint256 i; i < _ids.length; i++) {
            require(silhouettes[i].maxSupply > 0, "Silhouette does not exist");
            silhouettes[i].claimActive = _claimActive;
        }
    }

    function editSilhouetteMint(uint256[] calldata _ids, bool _mintActive)
        external
        onlyOwner
    {
        for (uint256 i; i < _ids.length; i++) {
            require(silhouettes[i].maxSupply > 0, "Silhouette does not exist");
            silhouettes[i].mintActive = _mintActive;
        }
    }

    function setAdminMinter(address _adminMinter) external onlyOwner {
        adminMinter = _adminMinter;
    }

    function setBeneficiaryAddress(address _beneficiaryAddress) external onlyOwner {
        beneficiaryAddress = _beneficiaryAddress;
    }

    function adminMint(
        uint256 _id,
        address _to,
        uint256 _amount
    ) public onlyAdminMinter {
        require(silhouettes[_id].maxSupply > 0, "Silhouette does not exist");
        require(
            (totalSupply(_id) + _amount) <= silhouettes[_id].maxSupply,
            "Max supply exceeded"
        );

        _mint(_to, _id, _amount, new bytes(0));
    }

    function claim(
        uint256 _id,
        uint256 _amount,
        uint256 _maxAmount,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused {
        require(silhouettes[_id].claimActive, "Claim is not active");
        require(
            totalSupply(_id) + _amount <= silhouettes[_id].maxSupply,
            "Max supply exceeded"
        );
        require(
            (silhouettes[_id].claimed[msg.sender] + _amount) <= _maxAmount,
            "Attempting to mint too many tokens"
        );

        bytes32 node = keccak256(abi.encodePacked(_id, msg.sender, _maxAmount));
        require(
            MerkleProof.verify(_merkleProof, silhouettes[_id].merkleRoot, node),
            "Invalid proof"
        );

        silhouettes[_id].claimed[msg.sender] =
            silhouettes[_id].claimed[msg.sender] +
            _amount;

        _mint(msg.sender, _id, _amount, new bytes(0));
        emit Claimed(_id, msg.sender, _amount);
    }

    function mint(uint256 _id, uint256 _amount) external payable whenNotPaused {
        require(silhouettes[_id].mintActive, "Mint is not active");
        require(
            msg.value == _amount * silhouettes[_id].mintPrice,
            "Incorrect eth amount"
        );
        require(
            _amount <= silhouettes[_id].maxMintTx,
            "Attempting to mint too many tokens"
        );
        require(
            totalSupply(_id) + _amount <= silhouettes[_id].maxSupply,
            "Max supply exceeded"
        );
        if (silhouettes[_id].maxMint > 0) {
            require(
                (silhouettes[_id].minted[msg.sender] + _amount) <=
                    silhouettes[_id].maxMint,
                "Attempting to mint too many tokens"
            );

            silhouettes[_id].minted[msg.sender] =
                silhouettes[_id].minted[msg.sender] +
                _amount;
        }

        _mint(msg.sender, _id, _amount, new bytes(0));
        emit Minted(_id, msg.sender, _amount);
    }

    function totalSupplyAll() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_counter.current());

        for (uint256 i; i < _counter.current(); i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(
            exists(_id),
            "ERC1155Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    super.uri(_id),
                    silhouettes[_id].metadataHash,
                    baseExtension()
                )
            );
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(beneficiaryAddress).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}