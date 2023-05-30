// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./utils/ERC721/ERC721Claimable.sol";
import "./utils/VRF/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniqGenesis is ERC721Claimable, VRFConsumerBase {

    // ----- EVENTS ----- //
    event PrizeCollected(address indexed _winner, uint256 _tokenId);

    // ----- VARIABLES ----- //
    //Sale
    uint256 internal constant _maxUniqly = 10000;
    bool internal _saleStarted;
    uint256 internal _tokenPrice;
    

    //VRF + Prizes
    bytes32 internal immutable keyHash;
    uint256 internal immutable fee;
    uint256 public randomResult;
    address[] public winners;

    // ----- CONSTRUCTOR ----- //
    constructor(
        string memory _bURI,
        string memory _name,
        string memory _symbol,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _proxyRegistryAddress,
        address _claimingContractAddress,
        uint256 _tokenSalePrice,
        uint256 _royaltyFee
    )
        ERC721Claimable(_name, _symbol, _bURI, _proxyRegistryAddress,_claimingContractAddress, _royaltyFee)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        keyHash = _keyHash;
        fee = _fee;
        _tokenPrice = _tokenSalePrice;
    }

    // ----- VIEWS ----- //
    function contractURI() public pure returns (string memory) {
        return "https://uniqly.io/api/nft-genesis/";
    }

    function calculateEthPriceForExactUniqs(uint256 _number)
        external
        view
        returns (uint256)
    {
        return _number * _tokenPrice;
    }
    
    function getAllWinners() external view returns (address[] memory) {
        uint256 winnersCount = winners.length;
        if (winnersCount == 0) {
            return new address[](0);
        } else {
            address[] memory result = new address[](winnersCount);
            uint256 index;
            for (index = 0; index < winnersCount; index++) {
                result[index] = winners[index];
            }
            return result;
        }
    }

    function getWinner(uint256 _arrayKey) external view returns (address) {
        return winners[_arrayKey];
    }

    function getWinnersCount() external view returns (uint256) {
        return winners.length;
    }

    function checkWin(uint256 _tokenId) external view returns (bool) {
        return _isWinner(_tokenId);
    }

        function isAlreadyRececeivedPrize(address _potWinner)
        external
        view
        returns (bool)
    {
        return (_isAlreadyRececeivedPrize(_potWinner));
    }

    function _isAlreadyRececeivedPrize(address _potWinner)
        internal
        view
        returns (bool)
    {
        uint256 i;
        uint256 winnersCount = winners.length;
        for (i = 0; i < winnersCount; i++) {
            if (winners[i] == _potWinner) return true;
        }
        return false;
    }

    // ----- PUBLIC METHODS ----- //
    //emits Transfer event
    function mintUniqly(uint256 numUniqlies) external payable {
        require(_saleStarted, "Sale not started yet");
        uint256 requiredValue = numUniqlies * _tokenPrice;
        uint256 mintIndex = totalSupply();
        require(msg.value >= requiredValue, "Not enough ether");
        require(
            (numUniqlies + mintIndex) <= _maxUniqly,
            "You cannot buy that many tokens"
        );

        for (uint256 i = 0; i < numUniqlies; i++) {
            _safeMint(msg.sender, mintIndex);
            mintIndex++;
        }
        // send back ETH if one overpay by accident
        if (requiredValue < msg.value) {
            payable(msg.sender).transfer(msg.value - requiredValue);
        }
    }

    function collectPrize(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Ownership needed");
        require(_isWinner(_tokenId), "You did not win");
        require(
            !_isAlreadyRececeivedPrize(msg.sender),
            "Already received a prize"
        );
        require(winners.length < 10, "Prize limit reached");
        winners.push(msg.sender);
        emit PrizeCollected(msg.sender, _tokenId);
        payable(msg.sender).transfer(1 ether);
    }

    receive() external payable {}

    // ----- PRIVATE METHODS ----- //
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function _isWinner(uint256 id) internal view returns (bool) {
        require(randomResult > 0, "Random must be initiated");
        uint256 result = (
            uint256(keccak256(abi.encodePacked(id, randomResult)))
        ) % 10000;
        if (result <= 20) return true;
        return false;
    }

    // ----- OWNERS METHODS ----- //
    function getRandomNumber(uint256 adminProvidedSeed)
        external
        onlyOwner
        returns (bytes32)
    {
        require(totalSupply() >= _maxUniqly, "Sale must be ended");
        require(randomResult == 0, "Random number already initiated");
        require(address(this).balance >= 10 ether, "min 10 ETH balance required");
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        return requestRandomness(keyHash, fee, adminProvidedSeed);
    }

    function batchMintAsOwner(
        uint[] memory _ids,
        address[] memory _addresses
    ) external onlyOwner {
        uint len = _ids.length;
        require(len == _addresses.length, "Arrays length");
        uint256 i = 0;
        for (i = 0; i < len; i++) {
            _safeMint(_addresses[i], _ids[i]);
        }
    }

    function editSaleStatus(bool _isEnable) external onlyOwner{
        _saleStarted = _isEnable;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function recoverERC20(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }

    function setRandomResualAsAdmin(uint256 _newRandomResult) external onlyOwner{
        require(randomResult == 0, "Random number already initiated");
        randomResult = _newRandomResult;
    }
    
    function editTokenPrice(uint256 _newPrice) external onlyOwner{
        _tokenPrice = _newPrice;
    }

    function editTokenUri(string memory _ttokenUri) external onlyOwner {
        _token_uri = _ttokenUri;
    }
}

interface Ierc20 {
    function transfer(address, uint256) external;
}