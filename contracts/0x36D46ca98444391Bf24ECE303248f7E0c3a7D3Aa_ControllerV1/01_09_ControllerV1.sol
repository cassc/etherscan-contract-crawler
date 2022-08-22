// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*Main Function
(1)Mint Boy;
(2)Mint Horse,Arms */
contract ControllerV1 is Ownable, ReentrancyGuard, Pausable {
    string public constant name = "SagittariusBoy Controller V1";

    string public constant version = "0.1";

    using Address for address;
    using Address for address payable;
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    mapping(uint8 => Counters.Counter) private _tokenIdCounters;

    /*RND address */
    address internal _rndTokenAddress;
    /*Team address */
    address internal _teamAddress;
    /*Treasury address */
    address internal _treasuryAddress;
    /*Income address */
    address internal _incomeAddress;

    /*Staking RND token amount */
    uint256 internal _stakingRND = 450000000000000000000000000;
    /*Treasury received RND token amount */
    uint256 internal _treasuryReceivedRND = 300000000000000000000000000;
    /*Recommender received RND token amount */
    uint256 internal _recommenderReceivedRND = 100000000000000000000000000;
    /*Team received RND token amount */
    uint256 internal _teamReceivedRND = 50000000000000000000000000;

    /* 0: The price of Mint 1 BoyToken
       1: The price of Mint 1 Horse and 1 Arms
    */
    mapping(uint8 => uint256) internal _prices;

    /*token mapping */
    mapping(uint8 => address) internal _tokens;

    /* token max supply mapping*/
    mapping(uint8 => uint256) internal _maxSupply;

    /* mint limit per address*/
    mapping(uint8 => uint256) internal _mintLimits;

    /*free mint */
    mapping(address => uint256) internal _freemints;

    /* free minted list*/
    mapping(address => uint256) internal _freeminted;

    /*Freemint end data */
    uint256 internal _freemintEndDate = 0;

    constructor(
        address rndTokenAddress,
        address teamAddress,
        address treasuryAddress,
        address incomeAddress,
        address boyToken,
        address horseToken,
        address armsToken
    ) {
        _rndTokenAddress = rndTokenAddress;
        _teamAddress = teamAddress;
        _treasuryAddress = treasuryAddress;
        _incomeAddress = incomeAddress;
        _prices[0] = 0;
        _prices[1] = 13000000000000000;

        _tokens[0] = boyToken;
        _tokens[1] = horseToken;
        _tokens[2] = armsToken;

        _maxSupply[0] = 10000;
        _maxSupply[1] = 10000;
        _maxSupply[2] = 10000;

        _mintLimits[0] = 8;
        _mintLimits[1] = 10;
        _mintLimits[2] = 10;

        _tokenIdCounters[0] = Counters.Counter(0);
        _tokenIdCounters[1] = Counters.Counter(0);
        _tokenIdCounters[2] = Counters.Counter(0);
    }

    function mintBoy(address recommender, uint8 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 mintPrice = _prices[0];
        require(
            SafeMath.mul(quantity, mintPrice) == msg.value,
            "invalid price"
        );

        address tokenAddress = _tokens[0];
        uint256 maxSupply = _maxSupply[0];
        uint256 mintLimit = _mintLimits[0];
        uint256 ownedCount = balanceOf(tokenAddress, msg.sender);
        require(
            SafeMath.add(quantity, ownedCount) <= mintLimit,
            "exceed max mint limit"
        );
        require(
            SafeMath.add(quantity, totalSupply(tokenAddress)) <= maxSupply,
            "exceed max supply"
        );
        uint256 freeCount = _freemints[msg.sender] > _freeminted[msg.sender]
            ? SafeMath.sub(_freemints[msg.sender], _freeminted[msg.sender])
            : 0;
        bool isFreeMint = freeCount >= quantity;
        if (isFreeMint == false) {
            uint256 treasuryRND = recommender == address(0)
                ? SafeMath.add(_treasuryReceivedRND, _recommenderReceivedRND)
                : _treasuryReceivedRND;
            uint256 recommenderRND = recommender != address(0)
                ? _recommenderReceivedRND
                : 0;
            uint256 teamRND = _teamReceivedRND;
            if (treasuryRND > 0) {
                uint256 totalTreasuryRND = SafeMath.mul(treasuryRND, quantity);
                _transferRND(_treasuryAddress, totalTreasuryRND);
            }
            if (recommenderRND > 0) {
                uint256 totalRecommenderRND = SafeMath.mul(
                    recommenderRND,
                    quantity
                );
                _transferRND(recommender, totalRecommenderRND);
            }
            if (teamRND > 0) {
                uint256 totalTeamRND = SafeMath.mul(teamRND, quantity);
                _transferRND(_teamAddress, totalTeamRND);
            }
        }
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounters[0].increment();
            uint256 tokenId = _tokenIdCounters[0].current();
            safeMint(tokenAddress, msg.sender, tokenId);
        }

        _freeminted[msg.sender] = SafeMath.add(
            _freeminted[msg.sender],
            quantity
        );
        payable(address(_incomeAddress)).sendValue(msg.value);
    }

    function _transferRND(address to, uint256 amount) internal {
        IERC20 rnd = IERC20(_rndTokenAddress);
        bool received = rnd.transferFrom(msg.sender, to, amount);
        require(received, "Transfer RND fail");
    }

    function mintHorseAndArms(uint8 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 horseAndArmsPrice = _prices[1];
        require(
            SafeMath.mul(quantity, horseAndArmsPrice) == msg.value,
            "invalid price"
        );
        for (uint8 i = 1; i <= 2; i++) {
            address tokenAddress = _tokens[i];
            uint256 maxSupply = _maxSupply[i];
            uint256 mintLimit = _mintLimits[i];
            uint256 ownedCount = balanceOf(tokenAddress, msg.sender);
            require(
                SafeMath.add(quantity, ownedCount) <= mintLimit,
                "exceed max mint limit"
            );
            require(
                SafeMath.add(quantity, totalSupply(tokenAddress)) <= maxSupply,
                "exceed max supply"
            );
            for (uint256 q = 0; q < quantity; q++) {
                _tokenIdCounters[i].increment();
                uint256 tokenId = _tokenIdCounters[i].current();
                safeMint(tokenAddress, msg.sender, tokenId);
            }
        }
        payable(address(_incomeAddress)).sendValue(msg.value);
    }

    function changeIncomeAddress(address incomeAddress) public onlyOwner {
        _incomeAddress = incomeAddress;
    }

    function getIncomeAddress() public view returns (address) {
        return _incomeAddress;
    }

    function changeToken(uint8 index, address token) public onlyOwner {
        _tokens[index] = token;
    }

    function getToken(uint8 index) public view returns (address) {
        return _tokens[index];
    }

    function changePrice(uint8 index, uint256 price) public onlyOwner {
        _prices[index] = price;
    }

    function getPrice(uint8 index) public view returns (uint256) {
        return _prices[index];
    }

    function changeMaxSupply(uint8 index, uint256 maxSupply) public onlyOwner {
        _maxSupply[index] = maxSupply;
    }

    function getMaxSupply(uint8 index) public view returns (uint256) {
        return _maxSupply[index];
    }

    function changeMintLimit(uint8 index, uint256 mintLimit) public onlyOwner {
        _mintLimits[index] = mintLimit;
    }

    function getMintLimit(uint8 index) public view returns (uint256) {
        return _mintLimits[index];
    }

    function changeFreeMintEndDate(uint256 freemintEndDate) public onlyOwner {
        _freemintEndDate = freemintEndDate;
    }

    function getFreeMintEndDate() public view returns (uint256) {
        return _freemintEndDate;
    }

    function addFreeMint(address[] calldata addrs, uint256 quantity)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addrs[i] != address(0)) {
                _freemints[addrs[i]] = quantity;
            }
        }
    }

    function getFreeMintCount(address addr) external view returns (uint256) {
        if (_freemintEndDate == 0 || _freemintEndDate > block.timestamp) {
            return
                _freemints[addr] > _freeminted[addr]
                    ? SafeMath.sub(_freemints[addr], _freeminted[addr])
                    : 0;
        }
        return 0;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(amount <= balance, "Insufficient balance");
        payable(to).transfer(amount);
    }

    function withdrawERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(token.transfer(to, amount), "Transfer failed");
    }

    event CallResponse(bool success, bytes data);

    function balanceOf(address target, address owner)
        internal
        returns (uint256)
    {
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("balanceOf(address)", owner)
        );
        emit CallResponse(success, result);
        require(success, "balanceOf_Proxy_CALL_FAIL");
        return abi.decode(result, (uint256));
    }

    function safeMint(
        address target,
        address to,
        uint256 tokenID
    ) internal {
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("safeMint(address,uint256)", to, tokenID)
        );
        emit CallResponse(success, result);
        require(success, "safeMint_Proxy_CALL_FAIL");
    }

    function totalSupply(address target) internal returns (uint256) {
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("totalSupply()")
        );
        emit CallResponse(success, result);
        require(success, "totalSupply_Proxy_CALL_FAIL");
        return abi.decode(result, (uint256));
    }
}