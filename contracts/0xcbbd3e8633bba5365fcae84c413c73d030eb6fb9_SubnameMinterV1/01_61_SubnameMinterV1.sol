//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {INameWrapper, PARENT_CANNOT_CONTROL, IS_DOT_ETH, CANNOT_UNWRAP, CANNOT_SET_RESOLVER, CANNOT_SET_TTL, CANNOT_CREATE_SUBDOMAIN, CAN_EXTEND_EXPIRY, CANNOT_BURN_FUSES} from "@ensdomains/ens-contracts/contracts/wrapper/INameWrapper.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "hardhat/console.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@ensdomains/ens-contracts/contracts/ethregistrar/BaseRegistrarImplementation.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@ensdomains/ens-contracts/contracts/ethregistrar/ETHRegistrarController.sol";

error InsufficientAmount(uint256 actual, uint256 want);
error NotEnsOwner();

error EnsNameNotRegistered(bytes32 parentNode);
error EnsNameExpired(bytes32 parentNode);
error EnsNameNotWrapped(bytes32 parentNode);
error NotEligible();

error FeesRecipientInvalid(address recipient);
error FeesTransferFailed(string reason);
error InvalidDurationUint();
error ExpiryGreaterThanParent();
error InvalidPriceNameLength();
error InvalidPriceDurationUint();
error InvalidDurationValue();
error SubnameNotRegistered();
error InvalidPrices();
error EnsNotSet();
error SubameIsEmpty();
error PriceNotSet();
error EligibilitiesMissMatch();

uint8 constant UNIT_MONTH = 1;
uint8 constant UNIT_YEAR = 2;
uint8 constant UNIT_MAX = 255;

struct Prices {
    uint256[] monthly; // length -> price
    uint256[] yearly;
    uint256[] lifetime;
}

struct Duration {
    uint8 unit;
    uint8 value;
}

struct Eligibilities {
    address[] tokens; // erc 721 or erc 20
    uint256[] amounts; // amount of token hold
}

struct Reward {
    address recipient;
    uint32 rate;
}

struct MintSetting {
    uint32 subnameFuses;
    Eligibilities eligibilities;
    Prices prices;
    address recipient;
}

contract SubnameMinterV1 is Ownable {
    using Address for address;
    using StringUtils for *;

    mapping(bytes32 => MintSetting) mintSettings;

    string public constant name = "SubnameMinterV1";
    uint64 public constant GRACE_PERIOD = 90 days;
    uint32 public serviceFeeRate = 1000; // max 10000
    address public ensAddress = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;
    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    // outside contracts
    AggregatorV3Interface public priceFeed;
    INameWrapper public nameWrapper;
    PublicResolver public publicResolver;

    event SubnameMinted(bytes32 parentNode, string name, uint256 expiry);
    event SubnameSetUp(bytes32 parentNode, Prices prices, address recipient);

    constructor(
        address wrapperAddres,
        address priceFeedAddress,
        address resolverAddress,
        address _ensAddress
    ) {
        nameWrapper = INameWrapper(wrapperAddres);
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        publicResolver = PublicResolver(resolverAddress);
        ensAddress = _ensAddress;
    }

    // manage functions
    function setServiceFeeRate(uint32 newServiceFeeRate) public onlyOwner {
        serviceFeeRate = newServiceFeeRate;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }

    function setWrapper(address newWrapperAddress) public onlyOwner {
        nameWrapper = INameWrapper(newWrapperAddress);
    }

    function setResolver(address resolverAddress) public onlyOwner {
        publicResolver = PublicResolver(resolverAddress);
    }

    function setPriceFeed(address priceFeedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function setEnsAddress(address _ensAddress) public onlyOwner {
        ensAddress = _ensAddress;
    }

    function latestETHPrice() private view returns (uint256) {
        (, int _price, , , ) = priceFeed.latestRoundData();
        return uint256(_price);
    }

    function settingsOf(
        bytes32 node
    ) public view returns (MintSetting memory) {
        return mintSettings[node];
    }

    function available(bytes32 node) public view returns (bool, uint64) {
        (address nodeOwner, , uint64 expiry) = nameWrapper.getData(
            uint256(node)
        );
        if (nodeOwner == address(0) || expiry <= block.timestamp) {
            return (true, 0);
        }
        return (false, expiry);
    }

    function price(
        bytes32 parentNode,
        string calldata _name,
        Duration memory duration
    )
        public
        view
        returns (
            uint256 priceInWei,
            uint256 priceInUSD,
            Prices memory priceMatrix
        )
    {
        uint256 nameLength = _name.strlen();
        if (nameLength == 0) {
            revert SubameIsEmpty();
        }
        priceMatrix = mintSettings[parentNode].prices;
        if (priceMatrix.monthly.length == 0) {
            revert PriceNotSet();
        }

        nameLength = nameLength > priceMatrix.monthly.length
            ? priceMatrix.monthly.length
            : nameLength;

        if (duration.unit == UNIT_MONTH) {
            priceInUSD = priceMatrix.monthly[nameLength - 1] * duration.value;
        } else if (duration.unit == UNIT_YEAR) {
            priceInUSD = priceMatrix.yearly[nameLength - 1] * duration.value;
        } else if (duration.unit == UNIT_MAX) {
            priceInUSD = priceMatrix.lifetime[nameLength - 1];
            if (priceInUSD == 0) {
                if (
                    priceMatrix.monthly[nameLength - 1] != 0 ||
                    priceMatrix.yearly[nameLength - 1] != 0
                ) {
                    revert InvalidDurationUint();
                }
            }
        } else {
            revert InvalidDurationUint();
        }

        priceInWei = (1 ether * priceInUSD) / latestETHPrice();
    }

    function eligible(
        bytes32 parentNode,
        address owner,
        string memory subname
    ) public view returns (bool) {
        Eligibilities memory subnameEligibilities = mintSettings[parentNode]
            .eligibilities;
        if (subnameEligibilities.tokens.length == 0) {
            return true;
        }
        if (subname.strlen() == 0) {
            return true;
        }
        for (
            uint256 index = 0;
            index < subnameEligibilities.tokens.length;
            index++
        ) {
            address token = subnameEligibilities.tokens[index];
            uint256 holdAmount = subnameEligibilities.amounts[index];
            if (token == address(0)) {
                continue;
            }
            if (_isERC20(token)) {
                if (IERC20(token).balanceOf(owner) >= holdAmount) {
                    return true;
                }
            } else if (IERC165(token).supportsInterface(0x80ac58cd)) {
                if (token == ensAddress) {
                    bytes32 labelhash = keccak256(bytes(subname));
                    bytes32 ensNode = _makeNode(ETH_NODE, labelhash);
                    uint256 ensTokenId = uint256(labelhash);
                    (
                        address ensOwner,
                        uint32 fuses,
                        uint64 expiry
                    ) = nameWrapper.getData(uint256(ensNode));
                    uint256 gracePeriod = fuses & IS_DOT_ETH == IS_DOT_ETH
                        ? GRACE_PERIOD
                        : 0;
                    if (block.timestamp < expiry - gracePeriod) {
                        if (ensOwner == owner) {
                            return true;
                        }
                    }
                    BaseRegistrarImplementation registrar = BaseRegistrarImplementation(
                            token
                        );
                    if (!registrar.available(ensTokenId)) {
                        if (registrar.ownerOf(ensTokenId) == owner) {
                            return true;
                        }
                    }
                } else {
                    if (_isDigits(subname)) {
                        uint256 tokenId = _convertStringtToUint(subname);
                        try ERC721(token).ownerOf(tokenId) returns (
                            address nftOwner
                        ) {
                            return nftOwner == owner;
                        } catch {
                            return false;
                        }
                    } else {
                        if (ERC721(token).balanceOf(owner) >= holdAmount) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    // public writes
    function setUpSubname(
        bytes32 nodeL2Domain,
        address recipient,
        Prices calldata _prices,
        Eligibilities calldata _eligibilities,
        uint32 _subnameFuses
    ) public {
        // create
        if (_eligibilities.tokens.length != _eligibilities.amounts.length) {
            revert EligibilitiesMissMatch();
        }
        (bool avaliable, ) = available(nodeL2Domain);
        if (avaliable) {
            revert EnsNameNotRegistered(nodeL2Domain);
        }
        if (nameWrapper.ownerOf(uint256(nodeL2Domain)) != msg.sender) {
            revert NotEnsOwner();
        }
        if (
            _prices.monthly.length < 1 ||
            _prices.monthly.length != _prices.yearly.length ||
            _prices.monthly.length != _prices.lifetime.length
        ) {
            revert InvalidPrices();
        }
        mintSettings[nodeL2Domain].prices = _prices;
        mintSettings[nodeL2Domain].recipient = recipient;
        mintSettings[nodeL2Domain].eligibilities = _eligibilities;
        mintSettings[nodeL2Domain].subnameFuses = _subnameFuses;

        emit SubnameSetUp(nodeL2Domain, _prices, recipient);
    }

    function submint(
        bytes32 parentNode,
        address owner,
        string calldata _name,
        Duration memory duration,
        Reward[] memory rewards
    ) public payable {
        if (ensAddress == address(0)) {
            revert EnsNotSet();
        }
        if (
            duration.unit != UNIT_MONTH &&
            duration.unit != UNIT_YEAR &&
            duration.unit != UNIT_MAX
        ) {
            revert InvalidDurationUint();
        }
        if (duration.value < 1) {
            revert InvalidDurationValue();
        }
        if (!eligible(parentNode, owner, _name)) {
            revert NotEligible();
        }
        (, uint64 expectExpiry) = _checkparentNode(
            parentNode,
            duration,
            block.timestamp
        );
        _checkPrice(parentNode, _name, duration);
        _transferFees(parentNode, rewards);
        uint32 subnameFuses = mintSettings[parentNode].subnameFuses;
        nameWrapper.setSubnodeRecord(
            parentNode,
            _name,
            owner,
            address(publicResolver),
            0,
            subnameFuses,
            expectExpiry
        );
        emit SubnameMinted(parentNode, name, expectExpiry);
    }

    function renew(
        bytes32 parentNode,
        string calldata _name,
        Duration memory duration,
        Reward[] memory rewards
    ) public payable {
        if (ensAddress == address(0)) {
            revert EnsNotSet();
        }
        if (
            duration.unit != UNIT_MONTH &&
            duration.unit != UNIT_YEAR &&
            duration.unit != UNIT_MAX
        ) {
            revert InvalidDurationUint();
        }
        if (duration.value < 1) {
            revert InvalidDurationValue();
        }
        bytes32 labelhash = keccak256(bytes(_name));
        bytes32 subNode = keccak256(abi.encodePacked(parentNode, labelhash));
        (bool _available, uint64 expiry) = available(subNode);
        if (_available) {
            revert SubnameNotRegistered();
        }
        (, uint64 expectExpiry) = _checkparentNode(
            parentNode,
            duration,
            expiry
        );
        _checkPrice(parentNode, _name, duration);
        _transferFees(parentNode, rewards);
        nameWrapper.setChildFuses(parentNode, labelhash, 0, expectExpiry);
    }

    // private functions
    function _isDigits(string memory input) private pure returns (bool) {
        bytes memory inputBytes = bytes(input);
        for (uint i = 0; i < inputBytes.length; i++) {
            bytes1 currentByte = inputBytes[i];
            if (currentByte < "0" || currentByte > "9") {
                return false;
            }
        }
        return true;
    }

    function _convertStringtToUint(
        string memory _number
    ) private pure returns (uint256) {
        uint256 base = 10; // decimal base
        uint256 result = 0;
        bytes memory b = bytes(_number);
        for (uint i = 0; i < b.length; i++) {
            uint8 digit = uint8(b[i]) - 48; // 48 is the ASCII code of '0'
            require(digit <= 9); // make sure the character is a decimal digit
            result = result * base + digit;
        }
        return result;
    }

    function _makeNode(
        bytes32 node,
        bytes32 labelhash
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelhash));
    }

    function _isERC20(address tokenAddress) private view returns (bool) {
        // Perform a low-cost call to a standard ERC20 function
        (bool success, bytes memory data) = tokenAddress.staticcall(
            abi.encodeWithSignature("decimals()")
        );

        // If the call was successful, the address is likely an ERC20 token
        return (success && data.length != 0);
    }

    function _checkparentNode(
        bytes32 parentNode,
        Duration memory duration,
        uint256 oldExpiry
    ) private view returns (uint32, uint64 expectExpiry) {
        (bool avaiable, ) = available(parentNode);
        if (avaiable) {
            revert EnsNameNotRegistered(parentNode);
        }
        uint256 blockTs = block.timestamp;
        uint256 from = oldExpiry > blockTs ? oldExpiry : blockTs;

        try nameWrapper.getData(uint256(parentNode)) returns (
            address,
            uint32 fuses,
            uint64 expiry
        ) {
            uint256 gracePeriod = fuses & IS_DOT_ETH == IS_DOT_ETH
                ? GRACE_PERIOD
                : 0;
            if (block.timestamp > expiry - gracePeriod) {
                revert EnsNameExpired(parentNode);
            }
            if (duration.unit == UNIT_MONTH) {
                expectExpiry = uint64(from + duration.value * 30 days);
            } else if (duration.unit == UNIT_YEAR) {
                expectExpiry = uint64(from + duration.value * 365 days);
            } else if (duration.unit == UNIT_MAX) {
                expectExpiry = expiry;
            }
            if (expectExpiry > expiry) {
                revert ExpiryGreaterThanParent();
            }
            return (fuses, expectExpiry);
        } catch {
            revert EnsNameNotWrapped(parentNode);
        }
    }

    function _transferFees(
        bytes32 parentNode,
        Reward[] memory rewards
    ) private {
        address payable feeRecipient = payable(
            mintSettings[parentNode].recipient
        );
        if (feeRecipient == address(0)) {
            revert FeesTransferFailed("Fee recipient is empty");
        }
        uint256 transferAmount = (msg.value / 10000) * (10000 - serviceFeeRate);
        feeRecipient.transfer(transferAmount);
        if (serviceFeeRate == 0 || msg.value == 0) {
            return;
        }
        uint32 remainingRate = serviceFeeRate;
        for (uint256 i = 0; i < rewards.length; i++) {
            if (
                rewards[i].recipient != address(0) &&
                rewards[i].rate > 0 &&
                rewards[i].rate <= remainingRate
            ) {
                address payable rewardRecipient = payable(rewards[i].recipient);
                uint256 rewardAmount = (msg.value / 10000) * rewards[i].rate;
                rewardRecipient.transfer(rewardAmount);
                remainingRate = remainingRate - rewards[i].rate;
            }
        }
    }

    function _checkPrice(
        bytes32 parentNode,
        string calldata _name,
        Duration memory duration
    ) private {
        (uint256 totalPrice, , Prices memory priceMatrix) = price(
            parentNode,
            _name,
            duration
        );
        if (priceMatrix.monthly.length == 0) {
            revert PriceNotSet();
        }
        if (msg.value < totalPrice) {
            revert InsufficientAmount(msg.value, totalPrice);
        }
    }
}