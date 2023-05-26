//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IPair {
    function getReserves() external view returns ( uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast );
}

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the most-recently updated index of the observations array
    uint16 observationIndex;
    // the current maximum number of observations that are being stored
    uint16 observationCardinality;
    // the next maximum number of observations to store, triggered in observations.write
    uint16 observationCardinalityNext;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    // whether the pool is locked
    bool unlocked;
}
interface IUniswapV3PoolState {
    function slot0() external view returns(Slot0 memory);
}

interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IBurnable {
    function burn(uint256 amount) external;
}

contract ClaimSWC {
    /// @notice USDC token address
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    /// @notice WETH token address
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    /// @notice EHT/USDC lp
    address public constant USDC_WETH = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;

    /// @notice  airdrop merkle root
    address public constant COINBASE = 0xA9D1e08C7793af67e9d92fe308d5697FB81d3E43;
    /// @notice  nft
    INFT public constant NFT = INFT(0x9D90669665607F08005CAe4A7098143f554c59EF);

    /// @notice Merkle root of the SWC airdrop
    bytes32 public immutable merkleRoot;

    /// @notice SWC token address
    address public immutable swc;
    /// @notice SWC/ETH lp
    address public immutable swcEthePair;

    /// @notice snapshot last id
    uint public immutable snapshotId;

    /// @notice burn start block time
    uint64 public immutable burnStartBlock;
    /// @notice burn balnece
    uint public burnBalance;
    /// @notice claimed nft id
    mapping(uint => bool) public claimed;
    event Claimed(address indexed to, uint indexed nftId);

    /// @notice claimed
    mapping(address => bool) public claimedMerkle;

    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor(
        address _swc,
        bytes32 _merkleRoot,
        address _swcEthePair,
        uint _snapshotId,
        uint _burnBalance,
        uint _burnStartBlock
    ) {
        swc = _swc;
        merkleRoot = _merkleRoot;
        swcEthePair = _swcEthePair;
        snapshotId = _snapshotId;
        burnBalance = _burnBalance;
        burnStartBlock = uint64(block.timestamp + _burnStartBlock);
        owner = msg.sender;
    }

    function waiveOwner() external onlyOwner {
        owner = address(0);
    }

    function verify(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    ) public view {
        require(
            MerkleProof.verify(
                proof,
                merkleRoot, 
                keccak256(bytes.concat(keccak256(abi.encode(addr, amount))))
            ),
            "Invalid proof"
        );
    }

    function getNftAmount(uint _nftAmount) public view returns(uint) {
        (uint _ethRes, uint _swcRes) = swcPrice();
        uint _claimAmount;
        if ( _ethRes == 0 ) {
            _claimAmount = 1e9 ether;
        } else {
            _claimAmount = 1e24 * _swcRes / _ethRes / ethPrice();
        }
       
        if ( _claimAmount > 1e9 ether) _claimAmount = 1e9 ether;
        return _claimAmount * _nftAmount;
    }

    function _claim(address _to, uint _nftAmount) internal returns(uint) {
        uint _claimAmount = getNftAmount(_nftAmount);
        _safeTransfer(swc, _to, _claimAmount);
        _safeTransfer(swc, COINBASE, _claimAmount / 100);
        burnBalance -= _claimAmount;
        return _claimAmount;
    }

    function claim(
        bytes32[] calldata proof,
        address addr,
        uint256 nftAmount
    ) external returns(uint) {
        require(burnStartBlock >= block.timestamp, "burn end");
        require(claimedMerkle[addr] == false, "claimed");
        verify(proof, addr, nftAmount);
        claimedMerkle[addr] = true;
        return _claim(addr, nftAmount);
    }


    function nO(uint _userId) external view returns(address) {
        return NFT.ownerOf(_userId);
    }

    function claimAfter(uint[] calldata nftId) external {
        address _sender = msg.sender;
        for (uint i = 0; i < nftId.length; i++) {
            uint _nId = nftId[i];
            require(NFT.ownerOf(_nId) == _sender, "not owner");
            require(!claimed[_nId] && _nId > snapshotId, "claimed");
            claimed[_nId] = true;
            
            emit Claimed(_sender, _nId);
        }
        uint _claimAmount = nftId.length * 1e7 ether;
        _safeTransfer(swc, _sender, _claimAmount);
        _safeTransfer(swc, COINBASE, _claimAmount / 100);
    }

    function swcPrice() public view returns(uint, uint) {
        (uint112 _swcRes, uint112 _ethRes,) = IPair(swcEthePair).getReserves();
        if (_swcRes == 0 || _ethRes == 0) return (0,0);
        if (swc > WETH) (_swcRes, _ethRes) = (_ethRes, _swcRes);
        return (_ethRes , _swcRes);
    }

    function ethPrice() public view returns(uint) {
        Slot0 memory _slot0 = IUniswapV3PoolState(USDC_WETH).slot0();
        return 1e30 / (_slot0.sqrtPriceX96 * 1e6 / 2**96) ** 2;
    }
    
    /// @notice burn SWC
    function burn() public {
        require(burnStartBlock < block.timestamp, "not start");
        IBurnable(swc).burn(burnBalance);
    }
    
    /// @notice Upgrade preparation
    function shift(address token, address to, uint amount) external onlyOwner {
        _safeTransfer(token, to, amount);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }
}