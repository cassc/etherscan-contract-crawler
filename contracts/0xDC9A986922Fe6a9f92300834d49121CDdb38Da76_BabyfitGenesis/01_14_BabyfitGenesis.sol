// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "erc721a/contracts/ERC721A.sol";

contract BabyfitGenesis is ERC721A, Ownable, Pausable, PaymentSplitter {
    /* ----------------------------- USING FOR ----------------------------- */

    using SafeERC20 for ERC20;

    enum Phase {
        FreeMint,
        PreMint,
        PublicMint
    }

    struct Params {
        uint256 startTime;
        uint256 endTime;
        uint256 maxCountTotal;
        uint256 maxCountPerMint;
        uint256 price;
        bytes32 merkleRoot;
        Phase phase;
    }

    /* ----------------------------- VARIABLES ----------------------------- */

    /// @dev Param of the sale.
    Params public params;

    uint256 public immutable maxSupply;
    uint256 public reservedAmount;
    uint256 public freeMintUnlockDate;

    uint256[] public teamShares;
    address[] public team;
    string public baseURI;

    mapping(address => uint256) public freeMintClaimed;
    mapping(address => uint256) public preMintClaimed;
    mapping(address => uint256) public publicMintClaimed;
    mapping(address => bool) public freeMintHolders;
    mapping(address => address) public tokens;

    event SetBaseURI(string _baseURI);
    event SetMintParams(Params _params);
    event Mint(address indexed _to, uint256 _amount);
   


    constructor(
        uint256 _maxSupply,
        uint256 _freeMintUnlockDate,
        uint256 _reservedAmount,
        address[] memory _team,
        uint256[] memory _teamShares,  
        address _reserveWallet
        
    )
       ERC721A("Babyfit Genesis", "BFT")
        PaymentSplitter(_team, _teamShares)
    {
        maxSupply = _maxSupply;
        reservedAmount = _reservedAmount;
        team = _team;
        teamShares = _teamShares;
        freeMintUnlockDate = _freeMintUnlockDate; 
        _safeMint(_reserveWallet, _reservedAmount);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }


    function setAsset(
        address _token, 
        address _aggregator
    ) external onlyOwner {
        require(_aggregator!= address(0),
            "BabyFit: aggregator is zero");
        tokens[_token] = _aggregator;
    }

    function setMintParams(Params memory _params) external onlyOwner {
        require(_params.maxCountTotal > 0, "BabyFit: max Count total is zero");
        require(
            _params.maxCountPerMint > 0,
            "BabyFit: max Count per mint is zero"
        );
        require(
            (_params.startTime >= block.timestamp) &&
                (_params.endTime > _params.startTime),
            "BabyFit: times don't match"
        );
        if (_params.phase == Phase(0)){
            require(_params.price == 0,
            "BabyFit: price is not zero"
            );
        }
        params = _params;
        emit SetMintParams(_params);
    }

    function setFreeMintUnlockDate(uint256 _freeMintUnlockDate) external onlyOwner {
        freeMintUnlockDate = _freeMintUnlockDate;
    }


    function mint(address _to, uint256 _amount, address _token, bytes32[] calldata _merkleProof) external whenNotPaused payable {
        require(
            (block.timestamp >= params.startTime) &&
                (block.timestamp < params.endTime),
            "BabyFit: time is out of range"
        );

        require(
            totalSupply() + _amount <= maxSupply,
            "BabyFit: total supply limit"
        );

        require(
            _amount <= params.maxCountPerMint,
            "BabyFit: count per mint limit"
        );
        require(checkValidity(_merkleProof), "BabyFit: address not whitelisted");
        if (params.phase == Phase(0)) {
            require(
                _amount + freeMintClaimed[_to] <= params.maxCountTotal,
                "BabyFit: max count limit"
            );
            freeMintClaimed[_to]+= 1;
            freeMintHolders[_to] = true;
        }
        else if (params.phase == Phase(1)) {
            require(
                _amount + preMintClaimed[_to] <= params.maxCountTotal,
                "BabyFit: max count limit"
            );
             preMintClaimed[_to]+= 1;
        }

         else {
            require(
                _amount + publicMintClaimed[_to] <= params.maxCountTotal,
                "BabyFit: max count limit"
            );

            publicMintClaimed[_to]+= 1;
        }
        _pay(_amount, _token);
        _safeMint(_to, _amount);
        emit Mint(_to, _amount);

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function checkValidity(bytes32[] calldata _merkleProof) public view  returns (bool){
       if (params.merkleRoot ==  bytes32(0)){
         return true;
       } else {
       bytes32 _leafToCheck = keccak256(abi.encodePacked(msg.sender));
       return MerkleProof.verify(_merkleProof, params.merkleRoot, _leafToCheck);
       }
    }


    function getPrice(address _token) public view returns (uint256 _tokenPrice) {

        if (params.price == 0){
           _tokenPrice = 0;
        } else{
            AggregatorV3Interface _aggregator = AggregatorV3Interface(tokens[_token]);
            (, int256  _price, , , ) = _aggregator.latestRoundData();
            require(_price > 0, "BabyFit: negative price");
             _tokenPrice = (params.price * 10 ** _aggregator.decimals()) / uint256(_price);
        }
    }


    function _pay( uint256 _amount, address _token) internal {
        uint256 _price = getPrice(_token);
        uint256 _value = _amount * _price;
        if (_token == address(0)) {
            _checkPaymentETH(_value);
        } else {
            ERC20 token = ERC20(_token);
            uint8 _decimals = uint8(18) - uint8(token.decimals());
            token.safeTransferFrom(
                msg.sender,
                address(this),
                _value / (10 ** _decimals)
            );
        }

    }

    function _checkPaymentETH(uint256 _value) private view {
        uint256 _minPrice = ((_value * 995) / 1000);
        uint256 _maxPrice = ((_value * 1005) / 1000);
        require(msg.value >= _minPrice, "BabyFit: Not enough ETH");
        require(msg.value <= _maxPrice, "BabyFit: Too much ETH");
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function _beforeTokenTransfers(
        address from,
        address,
        uint256,
        uint256
    ) internal virtual override {

        if ((from != address(0)) && (freeMintHolders[from] == true)){
        require(
            (block.timestamp > freeMintUnlockDate),
            "BabyFit: transfer is locked");
        }
    }
    
}