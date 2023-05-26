// SPDX-License-Identifier: MIT
//Tes-Sal
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GiraffeTower {
    function getGenesisAddresses() public view returns (address[] memory) {}

    function getGenesisAddress(uint256 token_id)
        public
        view
        returns (address)
    {}

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {}

    struct Giraffe {
        uint256 birthday;
    }
    mapping(uint256 => Giraffe) public giraffes;
}

contract Gleaf is ERC20Burnable, Ownable {
    event LogNewAlert(string description, address indexed _from, uint256 _n);
    event NameChange(uint256 tokenId, string name);
    using SafeMath for uint256;
    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public giraffetowerAddress = 0xb487A91382cD66076fc4C1AF4D7d8CE7f929A9bA;
    //Mapping of giraffe to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;
    mapping(uint256 => uint256) tokenRound;
    mapping(uint256 => string) giraffeName;
    uint256 public nameChangePrice = 10 ether;
    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;
    uint256 public EMISSIONS_RATE = 11574070000000;
    uint256 public STAKED_EMISSIONS_RATE = 5787030000000;
    bool public CLAIM_STATUS = true;
    uint256 public CLAIM_START_TIME;
    uint256 totalDividends = 0;
    uint256 ownerRoyalty = 0;
    uint256 public OgsCount = 100;
    address pr = 0x044780Ef6d06BF528c03f423bF3D9d8a88837A3f;
    uint256 public MAX_TOKEN = 50;
    bool public STAKING_STATUS = true;
    uint256 public STAKE_CLAIM_START_TIME;
    uint256[] public stakedTokens;
     //Mapping of giraffe to timestamp
    mapping(uint256 => uint256) internal stakedTokenIdToTimeStamp;

    //Mapping of giraffe to staker
    mapping(uint256 => address) internal stakedTokenIdToStaker;

    //Mapping of staker to giraffe
    mapping(address => uint256[]) internal stakerToTokenIds;
    //Mapping of giraffeid to fee
    mapping(uint256 => uint256) public giraffeLendFee;

    event Received(address, uint256);

    constructor() ERC20("Gleaf", "GLEAF") {
        CLAIM_START_TIME = block.timestamp;
        STAKE_CLAIM_START_TIME = block.timestamp;
    }

    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function getGiraffeLendFee(uint256 token_id)
        public
        view
        returns (uint256 )
    {
        return giraffeLendFee[token_id];
    }


    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
                giraffeLendFee[tokenId] = 0;
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(STAKING_STATUS == true, "Staking Closed, try again later");
        require(
            tokenIds.length <= MAX_TOKEN,
            "Kindly Use the other function to unstake your giraffe!"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(giraffetowerAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    stakedTokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(giraffetowerAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            stakedTokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            stakedTokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one token staked!"
        );
        require(
            stakerToTokenIds[msg.sender].length <= MAX_TOKEN,
            "Kindly Use the other function to unstake your giraffe!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(giraffetowerAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
            if(stakedTokenIdToTimeStamp[tokenId] < STAKE_CLAIM_START_TIME){
                stakedTokenIdToTimeStamp[tokenId] = STAKE_CLAIM_START_TIME;
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - stakedTokenIdToTimeStamp[tokenId]) *
                    STAKED_EMISSIONS_RATE);

            removeTokenIdFromStaker(msg.sender, tokenId);

            stakedTokenIdToStaker[tokenId] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;
        require(
            tokenIds.length <= MAX_TOKEN,
            "Only unstake 20 per txn!"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakedTokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(giraffetowerAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
            if(stakedTokenIdToTimeStamp[tokenIds[i]] < STAKE_CLAIM_START_TIME){
                stakedTokenIdToTimeStamp[tokenIds[i]] = STAKE_CLAIM_START_TIME;
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - stakedTokenIdToTimeStamp[tokenIds[i]]) *
                    STAKED_EMISSIONS_RATE);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            stakedTokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function stakedclaimByTokenIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;
        require(
            tokenIds.length <= MAX_TOKEN,
            "Only claim 50 per txn!"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(stakedTokenIdToStaker[tokenIds[i]] != msg.sender){
                 require(
            IERC721(giraffetowerAddress).ownerOf(tokenIds[i]) == msg.sender,
            "Token is not claimable by you!"
        );
            }
        
         if(stakedTokenIdToTimeStamp[tokenIds[i]] < STAKE_CLAIM_START_TIME){
                stakedTokenIdToTimeStamp[tokenIds[i]] = STAKE_CLAIM_START_TIME;
            }

        totalRewards = totalRewards + ((block.timestamp - stakedTokenIdToTimeStamp[tokenIds[i]]) * STAKED_EMISSIONS_RATE);

        stakedTokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function stakedClaimAll() public {
        // require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakedTokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );
            if(stakedTokenIdToTimeStamp[tokenIds[i]] < STAKE_CLAIM_START_TIME){
                stakedTokenIdToTimeStamp[tokenIds[i]] = STAKE_CLAIM_START_TIME;
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - stakedTokenIdToTimeStamp[tokenIds[i]]) *
                    STAKED_EMISSIONS_RATE);

            stakedTokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function stakedGetAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 sct = stakedTokenIdToTimeStamp[tokenIds[i]];
            if(sct < STAKE_CLAIM_START_TIME){
               sct = STAKE_CLAIM_START_TIME;
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - sct) *
                    STAKED_EMISSIONS_RATE);
        }

        return totalRewards;
    }

    function stakedGetRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            stakedTokenIdToStaker[tokenId] != nullAddress,
            "Token is not staked!"
        );
        uint256 sct = stakedTokenIdToTimeStamp[tokenId];
        if(sct < STAKE_CLAIM_START_TIME){
               sct = STAKE_CLAIM_START_TIME;
            }
        uint256 secondsStaked = block.timestamp - sct;

        return secondsStaked * STAKED_EMISSIONS_RATE;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return stakedTokenIdToStaker[tokenId];
    }

    function getPr() public view returns (address) {
        return pr;
    }

    function setGiraffetowerAddress(address _giraffetowerAddress)
        public
        onlyOwner
    {
        giraffetowerAddress = _giraffetowerAddress;
        return;
    }

    function setEmissionRate(uint256 _emissionrate) public onlyOwner {
        EMISSIONS_RATE = _emissionrate;
        return;
    }

    function setStakedEmissionRate(uint256 _emissionrate) public onlyOwner {
        STAKED_EMISSIONS_RATE = _emissionrate;
        STAKE_CLAIM_START_TIME = block.timestamp;
        return;
    }

    function setStakingStatus(bool _status) public onlyOwner {
        STAKING_STATUS = _status;
        return;
    }

    function setMaxToken(uint256 _maxtoken) public onlyOwner {
        MAX_TOKEN = _maxtoken;
        return;
    }

    function setGiraffeLendFee(uint256[] memory tokenIds, uint256[] memory fees) public {
         for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakedTokenIdToStaker[tokenIds[i]] == msg.sender,
                "You cannot set lending fee!"
            );
            giraffeLendFee[tokenIds[i]] = fees[i];
        }
        return;
    }

    function setGiraffeName(uint256 tokenId, string memory name) public {
        if(stakedTokenIdToStaker[tokenId] != msg.sender){
            require(
            IERC721(giraffetowerAddress).ownerOf(tokenId) == msg.sender,
            "Token is not nameable by you!"
        );
        }
        require(validateName(name) == true, "Not a valid new name");
        require(
            sha256(bytes(name)) != sha256(bytes(giraffeName[tokenId])),
            "New name is same as the current one"
        );
        require(isNameReserved(name) == false, "Name already reserved");
        if(stakedTokenIdToStaker[tokenId] != msg.sender){ //Allow Staked Users To change name for free
        uint256 allowance = allowance(msg.sender, pr);
        require(allowance >= nameChangePrice, "Check the token allowance");
        transferFrom(msg.sender, pr, nameChangePrice);
        }
        if (bytes(giraffeName[tokenId]).length > 0) {
            toggleReserveName(giraffeName[tokenId], false);
        }
        toggleReserveName(name, true);
        giraffeName[tokenId] = name;
        emit NameChange(tokenId, name);
    }

    function setPr(address _address) public onlyOwner{ 
        pr = _address;
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function getGiraffeName(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return giraffeName[tokenId];
    }
    

    function changeNamePrice(uint256 _price) external onlyOwner {
		nameChangePrice = _price;
	}

    function setClaimStatus(bool _claimstatus) public onlyOwner {
        CLAIM_STATUS = _claimstatus;
        return;
    }

     function claimByTokenIds(uint256[] memory tokenIds) public {
        GiraffeTower gt = GiraffeTower(giraffetowerAddress);
        uint256 totalRewards = 0;
        require(
            tokenIds.length <= MAX_TOKEN,
            "Only claim 50 per txn!"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(stakedTokenIdToStaker[tokenIds[i]] != msg.sender){
                 require(
            IERC721(giraffetowerAddress).ownerOf(tokenIds[i]) == msg.sender,
            "Token is not claimable by you!"
        );
            }
         if (tokenIdToTimeStamp[tokenIds[i]] == 0) {
                uint256 birthday = gt.giraffes(tokenIds[i]);
                uint256 stime = 0;
                if (birthday > CLAIM_START_TIME) {
                    stime = birthday;
                } else {
                    stime = CLAIM_START_TIME;
                }
                if (gt.getGenesisAddress(tokenIds[i]) == msg.sender && birthday < CLAIM_START_TIME) {
                    totalRewards += (4320000 * EMISSIONS_RATE);
                }
                tokenIdToTimeStamp[tokenIds[i]] = stime;
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function claimAll() public {
        require(CLAIM_STATUS == true, "Claim disabled!");
        GiraffeTower gt = GiraffeTower(giraffetowerAddress);
        address _address = msg.sender;
        uint256[] memory tokenIds = gt.walletOfOwner(_address);
        uint256[] memory stokenIds = getTokensStaked(_address);
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {

            if (tokenIdToTimeStamp[tokenIds[i]] == 0) {
                uint256 birthday = gt.giraffes(tokenIds[i]);
                uint256 stime = 0;
                if (birthday > CLAIM_START_TIME) {
                    stime = birthday;
                } else {
                    stime = CLAIM_START_TIME;
                }
                if (gt.getGenesisAddress(tokenIds[i]) == msg.sender && birthday < CLAIM_START_TIME) {
                    totalRewards = totalRewards + (4320000 * EMISSIONS_RATE);
                }
                tokenIdToTimeStamp[tokenIds[i]] = stime;
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        for (uint256 i = 0; i < stokenIds.length; i++) {

            if (tokenIdToTimeStamp[stokenIds[i]] == 0) {
                uint256 birthday = gt.giraffes(stokenIds[i]);
                uint256 stime = 0;
                if (birthday > CLAIM_START_TIME) {
                    stime = birthday;
                } else {
                    stime = CLAIM_START_TIME;
                }
                if (gt.getGenesisAddress(stokenIds[i]) == msg.sender && birthday < CLAIM_START_TIME) {
                    totalRewards = totalRewards + (4320000 * EMISSIONS_RATE);
                }
                tokenIdToTimeStamp[stokenIds[i]] = stime;
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[stokenIds[i]]) *
                    EMISSIONS_RATE);

            tokenIdToTimeStamp[stokenIds[i]] = block.timestamp;
        }
        require(totalRewards > 0, "LTR!");
        _mint(msg.sender, totalRewards);
    }

    function getAllRewards(address _address) public view returns (uint256) {
        GiraffeTower gt = GiraffeTower(giraffetowerAddress);
        uint256[] memory tokenIds = gt.walletOfOwner(_address);
        uint256[] memory stokenIds = getTokensStaked(_address);

        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIdToTimeStamp[tokenIds[i]] == 0) {
                uint256 birthday = gt.giraffes(tokenIds[i]);
                uint256 stime = 0;
                if (birthday > CLAIM_START_TIME) {
                    stime = birthday;
                } else {
                    stime = CLAIM_START_TIME;
                }
                if (gt.getGenesisAddress(tokenIds[i]) == _address && birthday < CLAIM_START_TIME) {
                    totalRewards = totalRewards + (4320000 * EMISSIONS_RATE);
                }
                totalRewards =
                    totalRewards +
                    ((block.timestamp - stime) * EMISSIONS_RATE);
            } else {
                totalRewards =
                    totalRewards +
                    ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                        EMISSIONS_RATE);
            }
        }

        for (uint256 i = 0; i < stokenIds.length; i++) {
            if (tokenIdToTimeStamp[stokenIds[i]] == 0) {
                uint256 birthday = gt.giraffes(stokenIds[i]);
                uint256 stime = 0;
                if (birthday > CLAIM_START_TIME) {
                    stime = birthday;
                } else {
                    stime = CLAIM_START_TIME;
                }
                if (gt.getGenesisAddress(stokenIds[i]) == _address && birthday < CLAIM_START_TIME) {
                    totalRewards = totalRewards + (4320000 * EMISSIONS_RATE);
                }
                totalRewards =
                    totalRewards +
                    ((block.timestamp - stime) * EMISSIONS_RATE);
            } else {
                totalRewards =
                    totalRewards +
                    ((block.timestamp - tokenIdToTimeStamp[stokenIds[i]]) *
                        EMISSIONS_RATE);
            }
        }
        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        GiraffeTower gt = GiraffeTower(giraffetowerAddress);
        uint256 birthday = gt.giraffes(tokenId);
        uint256 stime = 0;
        if (birthday > CLAIM_START_TIME) {
            stime = birthday;
        } else {
            stime = CLAIM_START_TIME;
        }
        uint256 totalRewards = 0;

        if (tokenIdToTimeStamp[tokenId] == 0) {
            if (gt.getGenesisAddress(tokenId) == msg.sender && birthday < CLAIM_START_TIME) {
                totalRewards = totalRewards + (4320000 * EMISSIONS_RATE);
            }
            totalRewards =
                totalRewards +
                ((block.timestamp - stime) * EMISSIONS_RATE);
        } else {
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    EMISSIONS_RATE);
        }

        return totalRewards;
    }

    function getBirthday(uint256 tokenId) public view returns (uint256) {
        GiraffeTower gt = GiraffeTower(giraffetowerAddress);
        uint256 birthday = gt.giraffes(tokenId);

        return birthday;
    }

    function _ownerRoyalty() public view returns (uint256) {
        return ownerRoyalty;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        uint256 tt = msg.value / 5;
        totalDividends += tt;
        uint256 ot = msg.value - tt;
        ownerRoyalty += ot;
    }

    function withdrawReward(uint256 tokenId) external {
        if(stakedTokenIdToStaker[tokenId] != msg.sender){
        require(
            IERC721(giraffetowerAddress).ownerOf(tokenId) == msg.sender &&
                tokenId <= 100,
            "WR:Invalid"
        );
        }
        require(tokenId <= 100, "Invalid");
        uint256 total = (totalDividends - tokenRound[tokenId]) / OgsCount;
        require(total > 0, "Too Low");
        tokenRound[tokenId] = totalDividends;
        sendEth(msg.sender, total);
    }

    function withdrawAllReward() external {
        address _address = msg.sender;
        GiraffeTower gt = GiraffeTower(giraffetowerAddress);
        uint256[] memory _tokensOwned = gt.walletOfOwner(_address);
        uint256[] memory _stokensOwned = getTokensStaked(_address);
        uint256 totalClaim = 0;
        for (uint256 i; i < _tokensOwned.length; i++) {
            if (_tokensOwned[i] <= 100) {
                totalClaim +=
                    (totalDividends - tokenRound[_tokensOwned[i]]) /
                    OgsCount;
                tokenRound[_tokensOwned[i]] = totalDividends;
            }
        }
        for (uint256 i; i < _stokensOwned.length; i++) {
            if (_stokensOwned[i] <= 100) {
                totalClaim +=
                    (totalDividends - tokenRound[_stokensOwned[i]]) /
                    OgsCount;
                tokenRound[_stokensOwned[i]] = totalDividends;
            }
        }
        require(totalClaim > 0, "WAR: LTC");
        sendEth(msg.sender, totalClaim);
    }

    function withdrawRoyalty() external onlyOwner {
        require(ownerRoyalty > 0, "WRLTY:Invalid");
        uint256 total = ownerRoyalty;
        ownerRoyalty = 0;
        sendEth(msg.sender, total);
    }

    function rewardBalance(uint256 tokenId) public view returns (uint256) {
           require(tokenId < 100 , "RB:Invalid");
        uint256 total = (totalDividends - tokenRound[tokenId]) / OgsCount;
        return total;
    }

    function getAllReward(address _address) public view returns (uint256) {
        GiraffeTower gt = GiraffeTower(giraffetowerAddress);
        uint256[] memory _tokensOwned = gt.walletOfOwner(_address);
        uint256[] memory _stokensOwned = getTokensStaked(_address);
        uint256 totalClaim = 0;
        for (uint256 i; i < _tokensOwned.length; i++) {
            if (_tokensOwned[i] <= 100) {
                totalClaim +=
                    (totalDividends - tokenRound[_tokensOwned[i]]) /
                    OgsCount;
            }
        }
        for (uint256 i; i < _stokensOwned.length; i++) {
            if (_stokensOwned[i] <= 100) {
                totalClaim +=
                    (totalDividends - tokenRound[_stokensOwned[i]]) /
                    OgsCount;
            }
        }
        return totalClaim;
    }

    

    function withdrawFunds(uint256 amount) public onlyOwner {
        sendEth(msg.sender, amount);
    }

    function sendEth(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function withdrawToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "You do not have sufficient Balance"
        );
        token.transfer(recipient, amount);
    }
}