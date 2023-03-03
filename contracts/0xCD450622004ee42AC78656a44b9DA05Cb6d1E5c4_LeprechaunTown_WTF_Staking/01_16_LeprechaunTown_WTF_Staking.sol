// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
█     ▄███▄   █ ▄▄  █▄▄▄▄ ▄███▄   ▄█▄     ▄  █ ██     ▄      ▄     ▄▄▄▄▀ ████▄   ▄ ▄      ▄   
█     █▀   ▀  █   █ █  ▄▀ █▀   ▀  █▀ ▀▄  █   █ █ █     █      █ ▀▀▀ █    █   █  █   █      █  
█     ██▄▄    █▀▀▀  █▀▀▌  ██▄▄    █   ▀  ██▀▀█ █▄▄█ █   █ ██   █    █    █   █ █ ▄   █ ██   █ 
███▄  █▄   ▄▀ █     █  █  █▄   ▄▀ █▄  ▄▀ █   █ █  █ █   █ █ █  █   █     ▀████ █  █  █ █ █  █ 
    ▀ ▀███▀    █      █   ▀███▀   ▀███▀     █     █ █▄ ▄█ █  █ █  ▀             █ █ █  █  █ █ 
                ▀    ▀                     ▀     █   ▀▀▀  █   ██                 ▀ ▀   █   ██ 
                                                ▀                                             
  ▄ ▄     ▄▄▄▄▀ ▄████         ▄▄▄▄▄      ▄▄▄▄▀ ██   █  █▀ ▄█    ▄     ▄▀           .-. .-.                 
 █   █ ▀▀▀ █    █▀   ▀       █     ▀▄ ▀▀▀ █    █ █  █▄█   ██     █  ▄▀            (   |   )                 
█ ▄   █    █    █▀▀        ▄  ▀▀▀▀▄       █    █▄▄█ █▀▄   ██ ██   █ █ ▀▄        .-.:  |  ;,-.                
█  █  █   █     █           ▀▄▄▄▄▀       █     █  █ █  █  ▐█ █ █  █ █   █      (_ __`.|.'_ __)              
 █ █ █   ▀       █                      ▀         █   █    ▐ █  █ █  ███       (    ./Y\.    )                 
  ▀ ▀             ▀                              █   ▀       █   ██             `-.-' | `-.-'               
                                                                                       \ 
🌈 ☘️      +       ⌛      =       💰
Original Collection LeprechaunTown_WTF : 0x360C8A7C01fd75b00814D6282E95eafF93837F27
*/
/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract LeprechaunTown_WTF_Staking is ERC20, ERC721Holder, ERC1155Holder, Ownable{
    event PrizePoolWinner(address _winner, uint256 _prize, uint256 _gold);
    event DonationMade(address _donor, uint256 _amount);

    address payable public payments;
    address public projectLeader; // Project Leader Address
    address[] public admins; // List of approved Admins

    IERC721 public parentNFT_A; //main 721 NFT contract
    IERC1155 public parentNFT_B; //main 1155 NFT contract

    mapping(uint256 => address) public tokenOwnerOf_A;
    mapping(uint256 => uint256) public tokenStakedAt_A;

    mapping(uint256 => address) public tokenOwnerOf_B;
    mapping(uint256 => uint256) public tokenStakedAt_B;

    mapping(bool => mapping(uint256 => uint256)) public tokenBonus;

    struct Batch {
        bool stakable;
        uint256 min;
        uint256 max;
        uint256 bonus;
    }
    //maximum size of batchID array is 2^256-1
    Batch[] public batchID_A;
    Batch[] public batchID_B;

    bool public pausedStake_A = true;
    bool public pausedStake_B = true;

    uint256 public total_A;
    uint256 public total_B;

    uint256 public stakedCount_A;
    uint256 public stakedCount_B;

    uint256 public limitPerSession = 10;

    uint256 public EMISSION_RATE = (4 * 10 ** decimals()) / 1 days; //rate of max 4 tokens per day(86400 seconds) 
    //math for emission rate: EMISSION_RATE * 86400 = token(s) per day
    //uint256 private initialSupply = (10000 * 10 ** decimals()); //( 10000 )starting amount to mint to treasury in WEI

    uint256 public prizeFee = 0.0005 ether;
    uint256 public prizePool;
    uint256 public winningPercentage;
    uint256[] public goldPrizes;

    uint256 public randomCounter;
    uint256 public minRange = 0;
    uint256 public maxRange = 100;
    uint256 public targetNumber;

    struct Player {
        uint lastPlay;
        uint nextPlay;
    }

    mapping(uint8 => mapping(uint256 => Player)) public players;

    constructor(address _parentNFT_A, address _parentNFT_B) ERC20("$GOLD", "$GOLD") {
        parentNFT_A = IERC721(_parentNFT_A); // on deploy this is the main NFT contract (parentNFT_A)
        parentNFT_B = IERC1155(_parentNFT_B); // on deploy this is the main NFT contract (parentNFT_B)
        //_mint(msg.sender, initialSupply);
    }

    function setCollectionTotal(bool _contract_A, uint256 _total) public onlyAdmins {
        if(_contract_A){
            total_A = _total;
        }
        else{
            total_B = _total;
        }
    }

    function createModifyBatch(bool _create, uint256 _modifyID, bool _contract_A, bool _stakable, uint256 _min, uint256 _max, uint256 _bonus) external onlyAdmins {
        require(_min <= _max, "Min must be less than or equal to Max");
        // Store batch information in a struct
        Batch memory newBatch = Batch(
            _stakable,
            _min,
            _max,
            _bonus
        );
        if(_contract_A){
            if(_create){
                batchID_A.push(newBatch);
            }
            else{
                require(batchID_A.length > 0, "No Batches To Modify");
                batchID_A[_modifyID] = newBatch;
            }
        }
        else{
            if(_create){
                batchID_B.push(newBatch);
            }
            else{
                require(batchID_B.length > 0, "No Batches To Modify");
                batchID_B[_modifyID] = newBatch;
            }
        }
    }

    function canStakeChecker(bool _contract_A, uint256 _id) public view returns(bool) {
        if(_contract_A){
            for (uint256 i = 0; i < batchID_A.length; i++) {
                if (_id >= batchID_A[i].min && _id <= batchID_A[i].max){
                    if (batchID_A[i].stakable){
                        return true;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        else{
            for (uint256 i = 0; i < batchID_B.length; i++) {
                if (_id >= batchID_B[i].min && _id <= batchID_B[i].max){
                    if (batchID_B[i].stakable){
                        return true;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        return false;
    }

    function getBatchBonus(bool _contract_A, uint256 _id) public view returns(uint256) {
        if(_contract_A){
            for (uint256 i = 0; i < batchID_A.length; i++) {
                if (_id >= batchID_A[i].min && _id <= batchID_A[i].max){
                    if (batchID_A[i].bonus != 0){
                        return batchID_A[i].bonus;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        else{
            for (uint256 i = 0; i < batchID_B.length; i++) {
                if (_id >= batchID_B[i].min && _id <= batchID_B[i].max){
                    if (batchID_B[i].bonus != 0){
                        return batchID_B[i].bonus;
                    }
                    else{
                        break;
                    }
                }
            }
        }
        return 1;
    }

    /**
    @dev Admin can set the bonus multiplier of a ID.
    */
    function setTokenBonus(bool _contract_A, uint256 _id, uint256 _bonus) external onlyAdmins {
        tokenBonus[_contract_A][_id] = _bonus;
    }

    /**
    @dev Admin can set the limit of IDs per session.
    */
    function setLimitPerSession(uint256 _limit) external onlyAdmins {
        limitPerSession = _limit;
    }

    /**
    @dev Admin can set the EMISSION_RATE.
    */
    function setEmissionRate(uint256 _RatePerDay) external onlyAdmins {
        EMISSION_RATE = (_RatePerDay * 10 ** decimals()) / 1 days;
    }

    /**
    * @dev Admin can set the PAUSE state for contract A or B.
    * true = no staking allowed
    * false = staking allowed
    */
    function pauseStaking(bool _contract_A, bool _state) public onlyAdmins {
        if(_contract_A){
            pausedStake_A = _state;
        }
        else{
            pausedStake_B = _state;
        }
    }

    /**
    * @dev User can stake NFTs they own to earn rewards over time.
    * Note: User must set this contract as approval for all on the parentNFT contracts in order to stake NFTs.
    * This function only stakes NFT IDs from the parentNFT_A or parentNFT_B contract.
    */
    function stake(uint[] memory _tokenIDs, bool _contract_A) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        if(_tokenIDs.length == 1){
            require(canStakeChecker(_contract_A, _tokenIDs[0]), "Token Is Not Stakable");
            stakeOne(_tokenIDs[0], _contract_A);
        }
        else{
            stakeMultiple(_tokenIDs, _contract_A);
        }
    }

    function stakeOne(uint256 _tokenID, bool _contract_A) private {
        if(_contract_A){
            require(pausedStake_A != true, "Contract A Staking Paused");
            require(tokenOwnerOf_A[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_A.safeTransferFrom(msg.sender, address(this), _tokenID);
            tokenOwnerOf_A[_tokenID] = msg.sender;
            tokenStakedAt_A[_tokenID] = block.timestamp;
            stakedCount_A++;
        }
        else{
            require(pausedStake_B != true, "Contract B Staking Paused");
            require(tokenOwnerOf_B[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_B.safeTransferFrom(msg.sender, address(this), _tokenID, 1, "0x00");
            tokenOwnerOf_B[_tokenID] = msg.sender;
            tokenStakedAt_B[_tokenID] = block.timestamp;
            stakedCount_B++;
        }
    }

    function stakeMultiple(uint[] memory _tokenIDs, bool _contract_A) private {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            require(canStakeChecker(_contract_A, _tokenID), "Token(s) Is Not Stakable");
            stakeOne(_tokenID, _contract_A);
        }
    }

    /**
    * @dev User can check estimated rewards gained so far from an address that staked an NFT.
    * Note: The staker address must have an NFT currently staked.
    * The returned amount is calculated as Wei. 
    * Use https://etherscan.io/unitconverter for conversions or do math returnedValue / (10^18) = reward estimate.
    */
    function estimateRewards(uint[] memory _tokenIDs, bool _contract_A) public view returns (uint256) {
        uint256 timeElapsed;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            uint256 _batchBonus = getBatchBonus(_contract_A, _tokenID);
            uint256 _calcTime;
            if (_contract_A){
                require(tokenOwnerOf_A[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                _calcTime += (block.timestamp - tokenStakedAt_A[_tokenID]);
            }
            else{
                require(tokenOwnerOf_B[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                _calcTime += (block.timestamp - tokenStakedAt_B[_tokenID]);
            }

            if (tokenBonus[_contract_A][_tokenID] != 0) {
                timeElapsed += _calcTime * tokenBonus[_contract_A][_tokenID];
            }
            else{
                timeElapsed += _calcTime * _batchBonus;
            }
        }

        return timeElapsed * EMISSION_RATE;
    } 

    /**
    * @dev User can unstake NFTs to earn the rewards gained over time.
    * Note: User must have a NFT already staked in order to unstake and gain rewards.
    * This function only unstakes NFT IDs that they currently have staked.
    * Rewards are calculated based on the Emission_Rate.
    */
    function unstake(uint[] memory _tokenIDs, bool _contract_A) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        require(isOwnerOfAllStaked(msg.sender, _contract_A, _tokenIDs), "CANNOT UNSTAKE");

        uint256 reward = estimateRewards(_tokenIDs, _contract_A);

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            if(_contract_A){
                parentNFT_A.safeTransferFrom(address(this), msg.sender, _tokenID);
                delete tokenOwnerOf_A[_tokenID];
                delete tokenStakedAt_A[_tokenID];
                stakedCount_A--;
            }
            else{
                parentNFT_B.safeTransferFrom(address(this), msg.sender, _tokenID, 1, "0x00");
                delete tokenOwnerOf_B[_tokenID];
                delete tokenStakedAt_B[_tokenID];
                stakedCount_B--;
            }
        }
        _mint(msg.sender, reward); // Minting the reward tokens gained for staking
    }

    /**
    * @dev Allows Owner or Project Leader to set the parentNFT contracts to a specified address.
    * WARNING: Please ensure all users NFTs are unstaked before setting a new address
    */
    function setStakingContract(bool _contract_A, address _contractAddress) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");

        if(_contract_A){
            parentNFT_A = IERC721(_contractAddress); // set the main NFT contract (parentNFT_A)
        }
        else{
            parentNFT_B = IERC1155(_contractAddress); // set the main NFT contract (parentNFT_B)
        }
    }

    /**
    * @dev Returns the owner address of a specific token staked
    * Note: If address returned is 0x0000000000000000000000000000000000000000 token is not staked.
    */
    function getTokenOwnerOf(bool _contract_A, uint256 _tokenID) public view returns(address){
        if(_contract_A){
            return tokenOwnerOf_A[_tokenID];
        }
        else{
            return tokenOwnerOf_B[_tokenID];
        }
    }

    function isOwnerOfAllStaked(address _holder, bool _contract_A, uint[] memory _tokenIDs) public view returns(bool){
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];

            if(getTokenOwnerOf(_contract_A, _tokenID) == _holder){
                //HOLDER IS TRUE
            }
            else{
                return false;
            }
        }
        return true;
    }

    /**
    * @dev Returns the unix date the token was staked
    */
    function getStakedAt(bool _contract_A, uint256 _tokenID) public view returns(uint256){
        if(_contract_A){
            return tokenStakedAt_A[_tokenID];
        }
        else{
            return tokenStakedAt_B[_tokenID];
        }
    }

    /**
    * @dev Returns the total amount of tokens staked
    */
    function getTotalStaked() public view returns(uint256){
        return stakedCount_A + stakedCount_B;
    }

    /**
    * @dev Allows Admins to mint an amount of tokens to a specified address.
    * Note: _amount must be in WEI use https://etherscan.io/unitconverter for conversions.
    */
    function mintTokens(address _to, uint256 _amount) external onlyAdmins {
        _mint(_to, _amount); // Minting Tokens
    }

    /**
    @dev Set the minimum and maximum range values.
    @param _minRange The new minimum range value.
    @param _maxRange The new maximum range value.
    */
    function setRange(uint256 _minRange, uint256 _maxRange) public onlyAdmins {
        minRange = _minRange;
        maxRange = _maxRange;
    }

    /**
    @dev Set the prize pool percentage the winner will receive.
    @param _percentage The new prize pool percentage.
    @param _prizeFee The new prize pool entry fee.
    @param _goldPrizes The new set of gold prizes.
    */
    function setPrizePercentageAndFee(uint256 _percentage, uint256 _prizeFee, uint256[] memory _goldPrizes) public onlyAdmins {
        winningPercentage = _percentage;
        prizeFee = _prizeFee;
        goldPrizes = _goldPrizes;
    }

    /**
    @dev Set the target number that will determine the winner.
    @param _targetNumber The new target number.
    */
    function setTargetNumber(uint256 _targetNumber) public onlyAdmins {
        targetNumber = _targetNumber;
    }

    //determines if user has won
    function isWinner(uint _luckyNumber) internal view returns (bool) {
        return targetNumber == randomNumber(minRange, maxRange, _luckyNumber);
    }

    //"Randomly" returns a number >= _min and <= _max.
    function randomNumber(uint _min, uint _max, uint _luckyNumber) internal view returns (uint256) {
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            randomCounter,
            _luckyNumber)
        )) % (_max + 1 - _min) + _min;
        
        return random;
    }

    /**
    @dev Allows a user to play the Lucky Spin game by providing a lucky number and the ID of an ERC721 or ERC1155 token they hold or have staked.
    If the user holds the specified token and meets the requirements for playing again, a random number is generated to determine if
    they win the prize pool and/or a gold token prize. The payout is sent to the user's address and a PrizePoolWinner event is emitted.
    If the user does not win, they still receive a gold token prize.
    @param _luckyNumber The lucky number chosen by the user to play the game.
    @param _id The ID of the ERC721 or ERC1155 token that the user holds.
    */
    function luckySpin(uint _luckyNumber, uint256 _id) public payable returns (bool) {
        (bool playable, uint8 contractID) = canPlay(_id);
        require(playable, "You can't play again yet!");
        require(_luckyNumber <= maxRange && _luckyNumber >= minRange, "Lucky Number Must Be Within Given Min Max Range");
        require(msg.value >= (prizeFee), "Insufficient Funds");
        uint256 goldPayout = goldPrizes[0];
        prizePool += prizeFee;
        bool won = false;
        if (prizePool != 0 && isWinner(_luckyNumber)) {
            // Calculate the payout as a percentage of the prize pool
            uint256 payout = (prizePool * winningPercentage) / 100;
            if (payout > 0) {
                prizePool -= payout;
                // Send the payout to the player's address
                bool success = payable(msg.sender).send(payout);
                require(success, "Failed to send payout to player");
            }
            if (goldPrizes.length > 1) {
                uint256 spin = randomNumber(1, goldPrizes.length - 1, _luckyNumber);
                goldPayout = goldPrizes[spin];
            }
            
            _mint(msg.sender, goldPayout);
            emit PrizePoolWinner(msg.sender, payout, goldPayout);
            won = true;
        }
        else{
            _mint(msg.sender, goldPayout);
        }
        randomCounter++;
        players[contractID][_id].lastPlay = block.timestamp;
        players[contractID][_id].nextPlay = block.timestamp + 1 days;
        return won;
    }

    function hasTokenBalance(uint256 _id, address _user) public view returns (uint8) {
        uint8 _contractID = 0;
        if (_id <= total_A && parentNFT_A.ownerOf(_id) == _user || getTokenOwnerOf(true, _id) == _user) {
            _contractID += 1;
        }
        if (_id <= total_B && parentNFT_B.balanceOf(_user, _id) > 0 || getTokenOwnerOf(false, _id) == _user) {
            _contractID += 2;
        }
        return _contractID;
    }

    function canPlay(uint256 _id) public view returns (bool, uint8) {
        uint8 _contractID = hasTokenBalance(_id, msg.sender);
        require(_contractID > 0, "You don't have that token");
        if (_contractID == 1){
            //contract A
            //need to add a total supply check
            require(canStakeChecker(true, _id), "Token Is Not Playable");
            return (players[1][_id].nextPlay <= block.timestamp, 1);
        }
        if (_contractID == 2){
            //contract B
            //need to add a total supply check
            require(canStakeChecker(false, _id), "Token Is Not Playable");
            return (players[2][_id].nextPlay <= block.timestamp, 2);
        }
        if (_contractID == 3){
            //contract Both
            //need to add a total supply check
            if (players[1][_id].nextPlay <= block.timestamp){
                require(canStakeChecker(true, _id), "Token Is Not Playable");
                return (true, 1);
            }
            if (players[2][_id].nextPlay <= block.timestamp){
                require(canStakeChecker(false, _id), "Token Is Not Playable");
                return (true, 2);
            }
        }

        return (false, 0);
    }

    function donateToPrizePool() public payable{
        require(msg.value > 0, "Nothing Donated");
        prizePool += msg.value;
        emit DonationMade(msg.sender, msg.value);
    }

    /**
    @dev Admin can set the payout address.
    @param _address The address must be a wallet or a payment splitter contract.
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can pull funds to the payout address.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Admin payment address has not been set");
        uint256 payout = address(this).balance - prizePool;
        (bool success, ) = payable(payments).call{ value: payout } ("");
        require(success, "Failed to send funds to admin");
    }

    /**
    @dev Admin can pull ERC20 funds to the payout address.
    */
    function withdraw(address token, uint256 amount) public onlyAdmins {
        require(token != address(0), "Invalid token address");

        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));

        require(amount <= balance, "Insufficient balance");
        require(erc20Token.transfer(payments, amount), "Token transfer failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address.
    */
    receive() external payable {
        require(payments != address(0), "Pay?");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

     /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner or admin.
     */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "Admin Only: caller is not an admin");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(msg.sender == admins[i]){
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
     * @dev Owner and Project Leader can set the addresses as approved Admins.
     * Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
     */
    function setAdmins(address[] calldata _users) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
     * @dev Owner or Project Leader can set the address as new Project Leader.
     */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        projectLeader = _user;
    }

}