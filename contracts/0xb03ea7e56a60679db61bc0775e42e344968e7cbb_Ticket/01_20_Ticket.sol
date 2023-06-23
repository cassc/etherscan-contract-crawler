// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

interface INFT {
    /**
     * Mint token by ticket
     */
    function mintUseTicket(address ticketOwner, uint256 conditionId)
        external;
}


contract Ticket is ERC1155,
    Ownable,
    PaymentSplitter,
    RrpRequesterV0
{
    AggregatorV3Interface internal priceFeed;
    
    string public name;
    string public symbol;
    uint256[] public randomChanceToIndex;
    address public nftContract;
    uint256 public immutable maxSupply = 100000;
    uint256 public maxReward = 21000;
    uint256 public totalSupply;
    uint256 public gasCompensation;
    address public airnode;
    bytes32 public endpointIdUint256;
    address payable public sponsorWallet;

    struct RandomStatus {
        uint256 randomNumber;
        address sender;
        bool isExist;
    }

    mapping(bytes32 => RandomStatus) public requestIdToRandomStatus;
    
    event TicketOwned(address owner,  
                      uint256 amount);

    event RequestNumbers(bytes32 indexed requestId,
                         address indexed sender);

    event RequestRandomnessFulfilled(bytes32 indexed requestId,
                                     uint256 indexed conditionId
    );

    constructor(
                string memory _name,
                string memory _symbol,
                address _airnodeRrp,
                uint256[] memory _randomChanceToIndex,
                address[] memory _payees,
                uint256[] memory _shares,
                address _aggregatorInterface,
                string memory _uri)
                RrpRequesterV0(_airnodeRrp) 
    PaymentSplitter(_payees, _shares)
    ERC1155(_uri)
    {
        name = _name;
        symbol = _symbol;
        priceFeed = AggregatorV3Interface(_aggregatorInterface);
        randomChanceToIndex = _randomChanceToIndex;
    }

    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address payable _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    function buyTickets(uint256 amount) public payable {
        require(maxSupply >= totalSupply + amount, "There are not enough tickets");
        uint256 price = getLatestPrice();
        require(msg.value >= price * amount, "Not enough money");
        _mint(msg.sender, 1, amount, "");
        totalSupply += amount;
        emit TicketOwned(msg.sender, amount);
    }

    function sendReward(address to, uint256 amount) public onlyOwner {
        require(maxSupply >= totalSupply + amount, "There are not enough tickets");
        require(maxReward >= amount, "There are not enough rewards");
        _mint(to,1,amount,"");
        totalSupply += amount;
        maxReward -= amount;
        emit TicketOwned(msg.sender, amount);
    }

    function getLatestPrice() public view returns (uint256 pricePerTicket) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        pricePerTicket = uint256((3 * 10**26) / price);
        return pricePerTicket;
    }

    function requestNft() public payable returns (bytes32 requestId) {
        require(msg.value >= gasCompensation * block.basefee, "Not enough gas");
        require(balanceOf(msg.sender, 1) > 0, "You are not an owner");
        sponsorWallet.transfer(msg.value);
            requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            abi.encode(
                bytes32("1s"),
                bytes32("_minConfirmations"),
                bytes32("7")
            )
        );
        requestIdToRandomStatus[requestId].sender = msg.sender;
        requestIdToRandomStatus[requestId].isExist = true;
        _burn(msg.sender, 1, 1);
        emit RequestNumbers(requestId, msg.sender);
    }

    function fulfillUint256(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(
            requestIdToRandomStatus[requestId].isExist == true,
            "Request ID not known"
        );
        uint256 qrngUint256 = abi.decode(data, (uint256));
        uint256 randomResult = (qrngUint256 % 10000) + 1;
        requestIdToRandomStatus[requestId].randomNumber = randomResult;
        uint256 conditionId = getConditionIdByRandomNumber(randomResult);
        INFT c = INFT(nftContract);
        c.mintUseTicket(requestIdToRandomStatus[requestId].sender, conditionId);
        emit RequestRandomnessFulfilled(requestId, conditionId);
    }
    
    function getConditionIdByRandomNumber(uint256 randomNumber)
        private
        view
        returns (uint256 res)
    {
        uint256 dropId = 1;
        for (uint256 i = 1; i <= randomChanceToIndex.length; i++) {
            if (randomNumber <= randomChanceToIndex[i]) {
                res = dropId;
                return res;
            }
            dropId += 11;
        }
    }

    function setNftCollectionAddress(address nftContractAddress) public onlyOwner {
        nftContract = nftContractAddress;
    }
    
    function setGasCompensation(uint256 _gasCompensation) public onlyOwner {
        gasCompensation = _gasCompensation;
    }

    function getGasCompensationAndBlockFee() public view returns (uint256) {
        return gasCompensation * block.basefee;
    }
    
}