// SPDX-License-Identifier: MIT
// Collectify Launchapad Contracts v1.0.0
// Creator: Hging

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ERC20TOKEN is ERC20, Ownable {
    uint256 public maxSupply;
    uint256 public currentRound;
    uint8 public _decimals;

    struct MintTime {
        uint64 startAt;
        uint64 endAt;
    }

    struct TimeZone {
        int8 offset;
        string text;
    }

    struct MintState {
        bool privateMinted;
        bool publicMinted;
    }

    struct MintInfo {
        bytes32 merkleRoot;
        uint256 mintPrice;
        uint256 maxCountPerAddress;
        uint256 maxSupply;
        uint256 totalSupply;
        TimeZone timezone;
        MintTime privateMintTime;
        MintTime publicMintTime;
        mapping(address => bool) privateClaimList;
        mapping(address => bool) publicClaimList;
        uint256 _privateMintCount;
    }

    mapping(uint256 => MintInfo) public mintInfoList;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimal,
        uint256 _maxSupply
    ) ERC20(name, symbol) {
        maxSupply = _maxSupply;
        currentRound = 0;
        _decimals = decimal;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function isMinted(uint256 round, address owner) public view returns (MintState memory) {
        return(
            MintState(
                mintInfoList[round].privateClaimList[owner],
                mintInfoList[round].publicClaimList[owner]
            )
        );
    }


    function changeMerkleRoot(uint256 round, bytes32 _merkleRoot) public onlyOwner {
        require(round <= currentRound, "round is greater than current round");
        mintInfoList[round].merkleRoot = _merkleRoot;
    }

    function changeMintPrice(uint256 round, uint256 _mintPrice) public onlyOwner {
        require(round <= currentRound, "round is greater than current round");
        mintInfoList[round].mintPrice = _mintPrice;
    }

    function changeMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function changemaxPerAddress(uint256 round, uint256 _maxPerAddress) public onlyOwner {
        require(round <= currentRound, "round is greater than current round");
        mintInfoList[round].maxCountPerAddress = _maxPerAddress;
    }

    function changePrivateMintTime(uint256 round, MintTime memory _mintTime) public onlyOwner {
        require(round <= currentRound, "round is greater than current round");
        mintInfoList[round].privateMintTime = _mintTime;
    }

    function changePublicMintTime(uint256 round, MintTime memory _mintTime) public onlyOwner {
        require(round <= currentRound, "round is greater than current round");
        mintInfoList[round].publicMintTime = _mintTime;
    }

    function changeMintTime(uint256 round, MintTime memory _publicMintTime, MintTime memory _privateMintTime) public onlyOwner {
        require(round <= currentRound, "round is greater than current round");
        mintInfoList[round].privateMintTime = _privateMintTime;
        mintInfoList[round].publicMintTime = _publicMintTime;
    }

    function changeMintInfo(uint256 round, bytes32 _merkleRoot, uint256 _mintPrice, uint256 _maxPerAddress, uint256 _maxSupply, TimeZone memory _timezone, MintTime memory _publicMintTime, MintTime memory _privateMintTime) public onlyOwner {
        require(round <= currentRound, "round is greater than current round");
        mintInfoList[round].merkleRoot = _merkleRoot;
        mintInfoList[round].mintPrice = _mintPrice;
        mintInfoList[round].maxCountPerAddress = _maxPerAddress;
        mintInfoList[round].maxSupply = _maxSupply;
        mintInfoList[round].timezone = _timezone;
        mintInfoList[round].publicMintTime = _publicMintTime;
        mintInfoList[round].privateMintTime = _privateMintTime;
    }

    function createNewRound(bytes32 _merkleRoot, uint256 _mintPrice, uint256 _maxPerAddress, uint256 _maxSupply, TimeZone memory _timezone, MintTime memory _publicMintTime, MintTime memory _privateMintTime) public onlyOwner {
        ++currentRound;
        mintInfoList[currentRound].merkleRoot = _merkleRoot;
        mintInfoList[currentRound].mintPrice = _mintPrice;
        mintInfoList[currentRound].maxCountPerAddress = _maxPerAddress;
        mintInfoList[currentRound].maxSupply = _maxSupply;
        mintInfoList[currentRound].timezone = _timezone;
        mintInfoList[currentRound].publicMintTime = _publicMintTime;
        mintInfoList[currentRound].privateMintTime = _privateMintTime;
    }

    function privateMint(uint256 round, uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof) external payable {
        require(round <= currentRound, "round is greater than current round");
        require(block.timestamp >= mintInfoList[round].privateMintTime.startAt && block.timestamp <= mintInfoList[round].privateMintTime.endAt, "error: 10000 time is not allowed");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        require(supply + quantity <= mintInfoList[round].maxSupply, "error: 10001 supply exceeded");
        require(mintInfoList[round].mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        address claimAddress = _msgSender();
        require(!mintInfoList[round].privateClaimList[claimAddress], 'error:10003 already claimed');
        require(quantity <= whiteQuantity, "error: 10004 quantity is not allowed");
        require(
            MerkleProof.verify(merkleProof, mintInfoList[round].merkleRoot, keccak256(abi.encodePacked(claimAddress, whiteQuantity))),
            'error:10004 not in the whitelist'
        );
        _mint( claimAddress, quantity );
        mintInfoList[round].privateClaimList[claimAddress] = true;
        mintInfoList[round]._privateMintCount = mintInfoList[round]._privateMintCount + quantity;
        mintInfoList[round].totalSupply = mintInfoList[round].totalSupply + quantity;
    }

    function publicMint(uint256 round, uint256 quantity) external payable {
        require(round <= currentRound, "round is greater than current round");
        require(block.timestamp >= mintInfoList[round].publicMintTime.startAt && block.timestamp <= mintInfoList[round].publicMintTime.endAt, "error: 10000 time is not allowed");
        require(quantity <= mintInfoList[round].maxCountPerAddress, "error: 10004 max per address exceeded");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        require(supply + quantity <= mintInfoList[round].maxSupply, "error: 10001 supply exceeded");
        require(mintInfoList[round].mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        address claimAddress = _msgSender();
        require(!mintInfoList[round].publicClaimList[claimAddress], 'error:10003 already claimed');
        _mint( claimAddress, quantity );
        mintInfoList[round].publicClaimList[claimAddress] = true;
        mintInfoList[round].totalSupply = mintInfoList[round].totalSupply + quantity;
    }

    function airdrop(uint256 quantity, address to) external {
        require(quantity <= maxSupply, "error: 10001 supply exceeded");
        _mint( to, quantity );
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC20).interfaceId;
    }

    // This allows the contract owner to withdraw the funds from the contract.
    function withdraw(uint amt) external onlyOwner {
        (bool sent, ) = payable(_msgSender()).call{value: amt}("");
        require(sent, "GG: Failed to withdraw Ether");
    }
}