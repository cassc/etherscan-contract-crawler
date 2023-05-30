// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721/ERC721Enumerable.sol";
import "./utils/Ownable.sol";
import "./utils/IERC2981.sol";
import "./utils/IERC20.sol";
import "./VRF/VRFConsumerBase.sol";

contract UniqDrop is ERC721Enumerable, IERC2981, Ownable, VRFConsumerBase {
    uint256 internal constant _maxUniqly = 10000;

    //VRF + Prizes
    bytes32 internal immutable keyHash;
    uint256 internal immutable fee;
    uint256 public randomResult;
    address[] public winners;
    bool baseURILock;

    function MAX_UNIQLY() external pure returns (uint256) {
        return _maxUniqly;
    }

    bool internal _saleStarted;

    function hasSaleStarted() external view returns (bool) {
        return _saleStarted;
    }

    // The IPFS hash for all Uniqlies concatenated *might* stored
    // here once all Uniqlies are issued and if I figure it out
    string public METADATA_PROVENANCE_HASH;
    string public BASE_URI;

    uint256 public immutable ROYALTY_FEE;

    // save data on burn event tokenid=>message
    mapping(uint256 => string) private claimers;

    modifier notZeroAddress(address a) {
        require(a != address(0), "ZERO address can not be used");
        _;
    }

    constructor(
        string memory baseURI,
        string memory _name,
        string memory _symbol,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _owner_,
        address _proxyRegistryAddress
    )
        notZeroAddress(_vrfCoordinator)
        notZeroAddress(_link)
        notZeroAddress(_owner_)
        notZeroAddress(_proxyRegistryAddress)
        ERC721(_name, _symbol)
        VRFConsumerBase(_vrfCoordinator, _link)
        Ownable(_owner_)
    {
        BASE_URI = baseURI;
        keyHash = _keyHash;
        fee = _fee;
        proxyRegistryAddress = _proxyRegistryAddress;
        ROYALTY_FEE = 750000; //7.5%
    }

    function getRandomNumber(uint256 adminProvidedSeed)
        external
        onlyOwner
        returns (bytes32)
    {
        require(totalSupply() >= _maxUniqly, "Sale must be ended");
        require(randomResult == 0, "Random number already initiated");
        require(
            address(this).balance >= 10 ether,
            "min 10 ETH balance required"
        );
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee, adminProvidedSeed);
    }

    function setBaseURILock() external onlyOwner {
        require(!baseURILock, "Lock already enabled");
        baseURILock = true;
    }

    //fallback function
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
    }

    // 20/10000 chance to be winner
    function checkWin(uint256 _tokenId) external view returns (bool) {
        return _isWinner(_tokenId);
    }

    function _isWinner(uint256 id) internal view returns (bool) {
        require(randomResult > 0, "Random must be initiated");
        uint256 result =
            (uint256(keccak256(abi.encodePacked(id, randomResult)))) % 10000;
        if (result <= 20) return true;
        return false;
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

    event PrizeCollected(address indexed _winner, uint256 _tokenId);

    function collectPrize(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Ownership needed");
        require(_isWinner(_tokenId) == true, "You dint win");
        require(
            _isAlreadyRececeivedPrize(msg.sender) == false,
            "Already received a prize"
        );
        require(winners.length < 10, "Prize limit reached");
        winners.push(msg.sender);
        emit PrizeCollected(msg.sender, _tokenId);
        payable(msg.sender).transfer(1 ether);
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

    function getMessageHash(
        address _tokenOwner,
        uint256 _tokenId,
        string memory _claimersName
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(_tokenOwner, _tokenId, _claimersName));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignature(
        address _tokenOwner,
        uint256 _tokenId,
        string memory _claimersName,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash =
            getMessageHash(_tokenOwner, _tokenId, _claimersName);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // return information stored on burn event
    function claimerOf(uint256 tokenId) external view returns (string memory) {
        return claimers[tokenId];
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overridden
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    event Claim(
        address indexed _claimer,
        uint256 indexed _tokenId,
        string _claimersName
    );

    function burn(
        uint256 _tokenId,
        string memory _claimersName,
        bytes memory _signature
    ) external {
        require(randomResult > 0, "Lottery must be held"); //Comment this line for burning tests
        require(ownerOf(_tokenId) == msg.sender, "You need to own this token");
        require(
            verifySignature(msg.sender, _tokenId, _claimersName, _signature),
            "Signature is not valid"
        );
        claimers[_tokenId] = _claimersName;
        _burn(_tokenId);
        emit Claim(msg.sender, _tokenId, _claimersName);
    }

    /*
    @dev return all tokens owned by user
    @param _owner address to be listed
    */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    //returns array, where [0]-current price in ETH, [1]- supply available in this price,
    // [2] - next price
    function getPriceParameters() external view returns (uint256[3] memory) {
        return _getPriceParams();
    }

    function _getPriceParams() private view returns (uint256[3] memory arr) {
        uint256 tSupply = totalSupply();
        if (1499 - tSupply > 0)
            return [35000000000000000, 1499 - tSupply, 50000000000000000];
        else if (3499 - tSupply > 0)
            return [50000000000000000, 3499 - tSupply, 80000000000000000];
        else if (7499 - tSupply > 0)
            return [80000000000000000, 7499 - tSupply, 120000000000000000];
        else if (9499 - tSupply > 0)
            return [120000000000000000, 9499 - tSupply, 240000000000000000];
        else if (9899 - tSupply > 0)
            return [240000000000000000, 9899 - tSupply, 400000000000000000];
        else return [400000000000000000, 10000 - tSupply, 0];
    }

    function _calcEthForUniqs(uint256 _number) private view returns (uint256) {
        uint256 currentSupply = totalSupply();
        require(currentSupply < _maxUniqly, "Sale has already ended");
        require(
            (_number + currentSupply) <= _maxUniqly,
            "You cannot buy that many tokens"
        );
        uint256[3] memory priceParameters = _getPriceParams();
        if (priceParameters[1] > _number) return priceParameters[0] * _number;
        else
            return (priceParameters[1] *
                priceParameters[0] +
                priceParameters[2] *
                (_number - priceParameters[1]));
    }

    function calculateEthPriceForExactUniqs(uint256 _number)
        external
        view
        returns (uint256)
    {
        return _calcEthForUniqs(_number);
    }

    //emits Transfer event
    function mintUniqly(uint256 numUniqlies) external payable {
        require(_saleStarted, "Sale has not started yet");
        uint256 requiredValue = _calcEthForUniqs(numUniqlies);
        require(msg.value >= requiredValue, "Not enough ether");
        require(
            numUniqlies <= 30 && numUniqlies > 0,
            "You can buy minimum 1, maximum 30 Uniqs"
        );
        uint256 mintIndex = totalSupply();
        for (uint256 i = 0; i < numUniqlies; i++) {
            _safeMint(msg.sender, mintIndex);
            mintIndex++;
        }
        // send back ETH if one overpay by accident
        if (requiredValue < msg.value) {
            payable(msg.sender).transfer(msg.value - requiredValue);
        }
    }

    function initialMint(address to, uint256 amt) external onlyOwner {
        uint256 sup = totalSupply();
        require(sup + amt <= 100, "Up to 100");
        uint256 index;
        // Reserved for people who helped this project
        for (index = 0; index < amt; index++) {
            _safeMint(to, sup);
            sup++;
        }
    }

    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!baseURILock, "Cant update base URI: Lock enabled");
        BASE_URI = baseURI;
    }

    // start sale after initial mint!
    function startSale() external onlyOwner {
        _saleStarted = true;
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

    // royalty fee EIP2981 implementation
    // contract owner gets all
    function royaltyInfo(uint256)
        external
        view
        override
        returns (address receiver, uint256 amount)
    {
        return (owner(), ROYALTY_FEE);
    }

    function receivedRoyalties(
        address,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount
    ) external override {
        emit ReceivedRoyalties(owner(), _buyer, _tokenId, _tokenPaid, _amount);
    }

    // OpenSea stuff
    address proxyRegistryAddress;

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address own, address spend)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(own)) == spend) {
            return true;
        }

        return super.isApprovedForAll(own, spend);
    }
    
    receive() external payable {
    }
}

// To recover broken ERC20 token contracts like USDT
// that are not returning value on transfer
interface Ierc20 {
    function transfer(address, uint256) external;
}

// for OpenSea integration
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}