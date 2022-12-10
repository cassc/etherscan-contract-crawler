// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VRFV2Consumer.sol";

contract WC is
    VRFV2Consumer,
    ERC1155,
    AccessControl,
    Ownable,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply
{
    string public name =
        unicode"⚽ World Cup 2022 - Quarter-finals - currentpot.com";

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGEMENT_ROLE = keccak256("MANAGEMENT_ROLE");

    uint256 public mintPrice;
    uint256 public totalContribution = 0;
    uint256 public winningTeamId = 0; // 0 = no winner yet
    uint256 public endMintingTime = 1671375600;
    uint256 public totalShares = 0;
    uint256 public winsPerShare = 0;
    uint256 public totalContestants = 0;
    uint256 public adminMaxMint = 200;
    uint256 contributionShare = 75;
    uint256 referrerShare = 5;

    uint256[] public contestantsIds;

    constructor(
        uint256[] memory _contestantsIds,
        uint256 _mintPrice,
        uint64 subscriptionId,
        address _VRFConsumerBaseV2,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    )
        ERC1155("ipfs://QmbFUb76C5kYz7uHMengLjKkVy7GJ7GWjx181h7gNUv59W/")
        VRFV2Consumer(
            subscriptionId,
            _VRFConsumerBaseV2,
            _callbackGasLimit,
            _requestConfirmations,
            _keyHash
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MANAGEMENT_ROLE, msg.sender);
        mintPrice = _mintPrice;
        contestantsIds = _contestantsIds;
        totalContestants = _contestantsIds.length;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function transferOwnershipOpensea(
        address newOwner
    ) public onlyRole(ADMIN_ROLE) {
        _transferOwnership(newOwner);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(super.uri(id), Strings.toString(id), ".json");
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function setMintPrice(uint256 _mintPrice) public onlyRole(MANAGEMENT_ROLE) {
        mintPrice = _mintPrice;
    }

    modifier checkValidRequest(uint32 amount) {
        if (block.timestamp > endMintingTime) {
            revert MintRequestsDeadlineReached(endMintingTime, block.timestamp);
        }

        if (amount > 500) {
            revert OverMaxMintRequest(500, amount);
        }

        if (amount < 1) {
            revert UnderMinMintRequest(1, amount);
        }
        _;
    }

    function mintRandomRequest(
        uint32 amount,
        address referrer
    ) public payable whenNotPaused checkValidRequest(amount) {
        uint totalPrice = getPrice(amount);

        if (msg.sender == referrer) {
            revert CannotBeOwnReferrer();
        }

        if (msg.value != totalPrice) {
            revert IncorrectPaymentValue(totalPrice, msg.value);
        }

        (
            uint256 contributionAmount,
            uint256 referrerAmount
        ) = getContributionValues(totalPrice, referrer);

        totalContribution += contributionAmount;

        if (referrerAmount > 0) {
            payable(referrer).transfer(referrerAmount);
        }

        _requestRandomWords(msg.sender, amount);
    }

    function adminMintRandomRequest(
        address user,
        uint32 amount
    ) external onlyRole(ADMIN_ROLE) checkValidRequest(amount) {
        require(
            amount <= adminMaxMint,
            "Admin can't mint more than 200 tokens"
        );
        adminMaxMint -= amount;
        _requestRandomWords(user, amount);
    }

    function getPrice(uint256 amount) public view returns (uint256) {
        return amount * mintPrice;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        super.fulfillRandomWords(requestId, randomWords);

        uint[] memory tokenAmounts = new uint[](totalContestants);

        for (uint256 i = 0; i < randomWords.length; i++) {
            tokenAmounts[randomWords[i] % totalContestants] += 1;
        }

        (uint[] memory tokenIds, uint[] memory amounts) = getTokensToMint(
            contestantsIds,
            tokenAmounts
        );

        if (winningTeamId != 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (tokenIds[i] == winningTeamId) {
                    tokenIds[i] = 0;
                }
            }
        }

        _mintBatch(getUserByRequestId(requestId), tokenIds, amounts, "");
    }

    function withdrawReward() external {
        if (winningTeamId == 0) {
            revert NoWinnerYet();
        }

        uint256 userBalance = balanceOf(msg.sender, winningTeamId);

        if (userBalance == 0) {
            revert NoTokensToRedeem();
        }

        uint256 amount = winsPerShare * userBalance;

        _burn(msg.sender, winningTeamId, userBalance);
        _mint(msg.sender, 0, userBalance, "");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");

        emit RewardWithdrawn(msg.sender, amount);
    }

    function setWinner(uint256 teamId) public onlyRole(MANAGEMENT_ROLE) {
        require(teamId <= totalContestants, "Team id out of range");
        require(teamId > 0, "Team id must be greater than 0");
        require(winningTeamId == 0, "Winner already set");
        require(
            block.timestamp > endMintingTime + 2 hours + 30 minutes,
            "Game not finished yet"
        );
        
        winningTeamId = teamId;
        totalShares = totalSupply(winningTeamId);

        winsPerShare = totalShares != 0 ? totalContribution / totalShares : 0;
        emit WinnerSet(teamId);
    }

    function totalSupplyBatch(
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        uint256[] memory totalSupplies = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            totalSupplies[i] = totalSupply(ids[i]);
        }

        return totalSupplies;
    }

    function getTokensToMint(
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal pure returns (uint256[] memory ids, uint256[] memory amounts) {
        uint256 unique = 0;

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] > 0) {
                unique++;
            }
        }

        if (unique == _amounts.length) {
            return (_ids, _amounts);
        }

        ids = new uint256[](unique);
        amounts = new uint256[](unique);
        uint256 index = 0;
        for (uint256 i = 0; i < _amounts.length; i++)
            if (_amounts[i] > 0) {
                ids[index] = _ids[i];
                amounts[index] = _amounts[i];
                index++;
            }
    }

    function getContributionValues(
        uint256 amount,
        address referrer
    )
        internal
        view
        returns (uint256 contributionAmount, uint256 referrerAmount)
    {
        if (referrer != address(0)) {
            contributionAmount = (amount * contributionShare) / 100;
            referrerAmount = (amount * referrerShare) / 100;
        } else {
            uint256 bonusContribution = (amount * referrerShare) / 100 / 2;
            contributionAmount =
                (amount * contributionShare) /
                100 +
                bonusContribution;
            referrerAmount = 0;
        }
    }

    function reduceAdminMint(uint256 reduceAmount) public onlyRole(ADMIN_ROLE) {
        adminMaxMint -= reduceAmount;
    }

    function depositAdmin() public payable onlyRole(ADMIN_ROLE) {
        require(msg.value > 0, "Deposit amount must be greater than 0");
    }

    function withdrawAmount(uint256 amount) public onlyRole(MANAGEMENT_ROLE) {
        uint availableAmount = 0;

        if (winningTeamId != 0) {
            availableAmount =
                address(this).balance -
                totalSupply(winningTeamId) *
                winsPerShare;
        } else {
            availableAmount = address(this).balance - totalContribution;
        }

        require(amount <= availableAmount, "Overdrawn amount");

        if (amount == 0) {
            (bool success, ) = payable(msg.sender).call{value: availableAmount}(
                ""
            );
            require(success, "Transfer failed.");
        } else {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Transfer failed.");
        }
    }

    function emergencyWithdraw() public onlyRole(MANAGEMENT_ROLE) {
        require(
            block.timestamp > endMintingTime + 180 days,
            "6 months not passed yet"
        );

        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawStuckToken(
        address tokenAddress
    ) public onlyRole(MANAGEMENT_ROLE) {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    event WinnerSet(uint256 indexed teamId);
    event WinShareWithdrawn(address indexed user, uint256 amount);
    event RewardWithdrawn(address indexed user, uint256 amount);

    error IncorrectPaymentValue(uint256 expected, uint256 received);
    error OverMaxMintRequest(uint256 maxRandomMint, uint256 requested);
    error UnderMinMintRequest(uint256 minRandomMint, uint256 requested);
    error MintRequestsDeadlineReached(uint256 deadline, uint256 timestamp);
    error NoTokensToRedeem();
    error CannotBeOwnReferrer();
    error NoWinnerYet();
}