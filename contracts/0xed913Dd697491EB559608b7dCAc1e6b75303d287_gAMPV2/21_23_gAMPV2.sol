// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {ERC20, ERC20Permit, ERC20Votes, IERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import {Types} from "./Types.sol";
import {IAmplifierV2} from "./interfaces/IAmplifierV2.sol";
import {INFT} from "./interfaces/INFT.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract gAMPV2 is ERC20, ERC20Permit, ERC20Votes, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    IAmplifierV2 public amplifierContract;
    INFT public nfts;

    mapping(address => mapping(uint256 => uint256)) public lastMintedFromAmplifier;
    mapping(Types.FuseProduct => uint256) public totalAmountToMintPerProduct;
    mapping(address => mapping(uint256 => bool)) public hasClaimedPeriod;
    mapping(uint256 => uint256) public potPerPeriod;

    EnumerableSet.AddressSet private teamAddresses;

    uint256 public mintFee = 0.001 ether;
    uint256 public lastPot;
    uint256 public receivedThisPeriod;

    address public mintFeeRecipient = 0x58c5a97c717cA3A7969F82D670A9b9FF16545C6F;
    address public claimFeeRecipient = 0xcbA2712e9Ef4E47690BB73ddF10af1Dc26080131;

    uint16 public claimFee = 300;
    // Basis for above fee values
    uint16 public constant bps = 10_000;

    event PotAccrued(uint256 potAmount);
    event Claimed(address indexed claimant, uint256 indexed potBlock, uint256 amount);

    constructor(IAmplifierV2 _amplifierContract, uint256 _lastPot) ERC20("gAMPV2", "gAMP") ERC20Permit("gAMPV2") {
        amplifierContract = _amplifierContract;
        lastPot = _lastPot;

        totalAmountToMintPerProduct[Types.FuseProduct.OneYear] = 125e15;
        totalAmountToMintPerProduct[Types.FuseProduct.ThreeYears] = 380e15;
        totalAmountToMintPerProduct[Types.FuseProduct.FiveYears] = 1000e15;

        address ops = 0x9f3717CDB4ab19da03845E8a86668BEA8bab840B;
        address dev = 0x3460E67b0c5740ef21E390E681b3160Be372a016;

        _mint(ops, 40 ether);
        _mint(dev, 20 ether);

        _delegate(ops, ops);
        _delegate(dev, dev);

        teamAddresses.add(ops);
        teamAddresses.add(dev);
    }

    function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(_from, _to, _amount);
    }

    function _mint(address _to, uint256 _amount) internal override(ERC20, ERC20Votes) {
        super._mint(_to, _amount);
    }

    function _burn(address _account, uint256 _amount) internal override(ERC20, ERC20Votes) {
        super._burn(_account, _amount);
    }

    function mint(uint256[] calldata _ids) external payable nonReentrant {
        uint256 length = _ids.length;
        require(msg.value == mintFee * length, "Invalid Ether value provided");

        uint256 owed;

        for (uint256 i = 0; i < length;) {
            Types.AmplifierV2 memory amplifier = amplifierContract.amplifiers(_ids[i]);

            require(amplifier.minter == msg.sender, "Invalid ownership");
            require(amplifier.expires > block.timestamp, "Amplifier expired");
            require(amplifier.fuseProduct != Types.FuseProduct.None, "Must be fused");

            uint256 lastMintedFromThisAmplifier = lastMintedFromAmplifier[msg.sender][_ids[i]];

            // If they have fused again since last minting gAMP, we need to reset lastMintedFromAmplifier
            if (amplifier.fused >= lastMintedFromThisAmplifier) {
                lastMintedFromAmplifier[msg.sender][_ids[i]] = 0;
            }

            owed += getMintAmount(amplifier, lastMintedFromThisAmplifier);

            lastMintedFromAmplifier[msg.sender][_ids[i]] = block.timestamp;

            unchecked {
                ++i;
            }
        }

        require(owed > 0, "No gAMP owed");

        (bool success,) = mintFeeRecipient.call{value: msg.value}("");
        require(success, "Could not send ETH");

        _mint(msg.sender, owed);
        delegate(msg.sender);
    }

    function mintFromNFT(uint256 _amount) external nonReentrant {
        require(msg.sender == address(nfts), "Not the NFT contract");
        _mint(msg.sender, _amount);
        delegate(msg.sender);
    }

    function pot() external {
        require(block.timestamp >= lastPot + 30 days, "Cannot make a new pot too soon");

        lastPot = block.timestamp;
        potPerPeriod[block.number] = receivedThisPeriod;
        emit PotAccrued(receivedThisPeriod);

        receivedThisPeriod = 0;
    }

    function claim(uint256[] calldata _blockNumbers) external nonReentrant {
        require(!teamAddresses.contains(msg.sender), "Team addresses cannot claim");

        uint256 owed;

        uint256 length = _blockNumbers.length;
        for (uint256 i = 0; i < length;) {
            uint256 claimAmount = _claim(_blockNumbers[i]);
            emit Claimed(msg.sender, _blockNumbers[i], claimAmount);
            owed += claimAmount;
            unchecked {
                ++i;
            }
        }

        _claimPayments(owed);
    }

    function _claim(uint256 _blockNumber) internal returns (uint256) {
        require(!hasClaimedPeriod[msg.sender][_blockNumber], "Already claimied this period");
        hasClaimedPeriod[msg.sender][_blockNumber] = true;
        return getClaimAmount(_blockNumber);
    }

    function _claimPayments(uint256 owed) internal {
        require(owed > 0, "No ETH claimable");

        uint256 claimFeeAmount = (owed * claimFee) / bps;

        (bool success,) = claimFeeRecipient.call{value: claimFeeAmount}("");
        require(success, "Could not send ETH");

        owed -= claimFeeAmount;

        (success,) = msg.sender.call{value: owed}("");
        require(success, "Could not send ETH");
    }

    function getMintAmount(Types.AmplifierV2 memory _amplifier, uint256 _lastMintedFromThisAmplifier)
        public
        view
        returns (uint256)
    {
        uint256 end = (block.timestamp > _amplifier.unlocks) ? _amplifier.unlocks : block.timestamp;
        uint256 start = (_lastMintedFromThisAmplifier == 0) ? _amplifier.fused : _lastMintedFromThisAmplifier;

        uint256 numerator = end - start;
        uint256 denominator = _amplifier.unlocks - _amplifier.fused;

        return (totalAmountToMintPerProduct[_amplifier.fuseProduct] * numerator) / denominator;
    }

    function getClaimAmount(uint256 _blockNumber) public view returns (uint256) {
        return (potPerPeriod[_blockNumber] * getPastVotes(msg.sender, _blockNumber))
            / (getPastTotalSupply(_blockNumber) - getTeamTokens(_blockNumber));
    }

    function getTeamTokens(uint256 _blockNumber) public view returns (uint256) {
        uint256 teamTokens = 0;
        uint256 length = teamAddresses.length();

        for (uint256 i = 0; i < length;) {
            teamTokens += getPastVotes(teamAddresses.at(i), _blockNumber);

            unchecked {
                ++i;
            }
        }

        return teamTokens;
    }

    function gAMPOwed(uint256[] calldata _ids, address _minter) external view returns (uint256) {
        uint256 owed = 0;
        uint256 length = _ids.length;

        for (uint256 i = 0; i < length;) {
            Types.AmplifierV2 memory amplifier = amplifierContract.amplifiers(_ids[i]);
            require(amplifier.expires > block.timestamp, "Amplifier expired");
            require(amplifier.fuseProduct != Types.FuseProduct.None, "Must be fused");

            owed += getMintAmount(amplifier, lastMintedFromAmplifier[_minter][_ids[i]]);

            unchecked {
                ++i;
            }
        }
        return owed;
    }

    function ETHOwed(uint256[] memory _blockNumbers, address _claimant) public view returns (uint256) {
        uint256 owed = 0;
        for (uint256 i = 0; i < _blockNumbers.length;) {
            uint256 blockNumber = _blockNumbers[i];
            if (!hasClaimedPeriod[_claimant][blockNumber]) {
                owed += (potPerPeriod[blockNumber] * getPastVotes(_claimant, blockNumber))
                    / (getPastTotalSupply(blockNumber) - getTeamTokens(blockNumber));
            }

            unchecked {
                ++i;
            }
        }
        return owed;
    }

    function getTeamAddresses() external view returns (address[] memory) {
        return teamAddresses.values();
    }

    function setNFTs(INFT _nfts) external onlyOwner {
        nfts = _nfts;
    }

    function setFees(uint256 _mintFee, uint16 _claimFee) external onlyOwner {
        mintFee = _mintFee;
        claimFee = _claimFee;
    }

    function setTotalAmountToMintPerProduct(Types.FuseProduct _fuseProduct, uint256 _amount) external onlyOwner {
        totalAmountToMintPerProduct[_fuseProduct] = _amount;
    }

    function setFeeRecipients(address _mintFeeRecipient, address _claimFeeRecipient) external onlyOwner {
        mintFeeRecipient = _mintFeeRecipient;
        claimFeeRecipient = _claimFeeRecipient;
    }

    function setAmplifierContract(IAmplifierV2 _amplifierContract) external onlyOwner {
        amplifierContract = _amplifierContract;
    }

    function airdrop(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Lengths must match");
        uint256 length = _recipients.length;
        for (uint256 i = 0; i < length;) {
            _mint(_recipients[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addToTeamAddresses(address[] calldata _teamAddresses) external onlyOwner {
        uint256 length = _teamAddresses.length;
        for (uint256 i = 0; i < length;) {
            teamAddresses.add(_teamAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function removeFromTeamAddresses(address[] calldata _teamAddresses) external onlyOwner {
        uint256 length = _teamAddresses.length;
        for (uint256 i = 0; i < length;) {
            address teamAddress = _teamAddresses[i];
            require(teamAddresses.contains(teamAddress), "Not in set");
            teamAddresses.remove(_teamAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success,) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    receive() external payable {
        receivedThisPeriod += msg.value;
    }

    function setHasClaimedPerPeriod(address[] calldata _claimants, uint256[] calldata _blockNumbers) external onlyOwner {
        require(_claimants.length == _blockNumbers.length, "Arrays must be same length");
        for (uint256 i = 0; i < _claimants.length; ) {
            hasClaimedPeriod[_claimants[i]][_blockNumbers[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function setPotPerPeriod(uint256[] calldata _blockNumbers, uint256[] calldata _pots) external onlyOwner {
        require(_blockNumbers.length == _pots.length, "Arrays must be same length");
        for (uint256 i = 0; i < _blockNumbers.length; ) {
            potPerPeriod[_blockNumbers[i]] = _pots[i];
            unchecked {
                ++i;
            }
        }
    }
}