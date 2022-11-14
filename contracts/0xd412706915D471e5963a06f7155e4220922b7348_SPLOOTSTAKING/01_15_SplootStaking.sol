// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*,,,,,,,,
,,,,,,,,,(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,@@@@@@@@@@@,,,,,@@@@@@@@@@&,,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,@@@@(,,,@@@@,,,,@@@@,,,@@@@@,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,@@@@(,,,@@@@,,,,@@@@,,,@@@@@,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,@@@@@@@@@@@@,,,,@@@@@@@@@@@/,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,@@@@(,,,,(@@@@,,@@@@,,,,(@@@@,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,@@@@@@@@@@@@@,,,@@@@@@@@@@@@&,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,@@@@@@@@@@,,,,,,@@@@@@@@@@,,,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(*,,,,,,,,
,,,,,,,,,(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(*,,,,,,,,
,,,,,,,,,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
Staking Contract By Beeble Blocks
*/

contract SPLOOTSTAKING is ERC20, ERC721Holder, ERC1155Holder, Ownable{
    address public projectLeader; // Project Leader Address
    address[] public admins; // List of approved Admins

    IERC721 public parentNFT_A; //main 721 NFT contract
    IERC721 public parentNFT_B; //main 721 NFT contract #2
    IERC721 public parentNFT_C; //main 721 NFT contract #3

    mapping(uint256 => address) public tokenOwnerOf_A;
    mapping(uint256 => uint256) public tokenStakedAt_A;

    mapping(uint256 => address) public tokenOwnerOf_B;
    mapping(uint256 => uint256) public tokenStakedAt_B;

    mapping(uint256 => address) public tokenOwnerOf_C;
    mapping(uint256 => uint256) public tokenStakedAt_C;

    bool public pausedStake_A = false;
    bool public pausedStake_B = false;
    bool public pausedStake_C = false;

    uint256 public limitPerSession = 10;

    uint256 public EMISSION_RATE = (1 * 10 ** decimals()) / 1 days; //rate of max 1 tokens per day(86400 seconds) 
    //math for emission rate: EMISSION_RATE * 86400 = token(s) per day

    constructor(address _parentNFT_A, address _parentNFT_B, address _parentNFT_C) ERC20("$BEEBLE", "$BEEB") {
        parentNFT_A = IERC721(_parentNFT_A); // on deploy this is the main NFT contract (parentNFT_A)
        parentNFT_B = IERC721(_parentNFT_B); // on deploy this is the main NFT contract (parentNFT_B)
        parentNFT_C = IERC721(_parentNFT_C); // on deploy this is the main NFT contract (parentNFT_C)
    }

    /**
     * @dev Set the limit of tokenIDs per session.
     */
    function setLimitPerSession(uint256 _limit) external onlyAdmins {
        limitPerSession = _limit;
    }

    /**
     * @dev Set the EMISSION_RATE.
     */
    function setEmissionRate(uint256 _RatePerDay) external onlyAdmins {
        EMISSION_RATE = (_RatePerDay * 10 ** decimals()) / 1 days;
    }

    /**
     * @dev Admin can set the PAUSE state for contract A, B or C
     * true = no staking allowed
     * false = staking allowed
     */
    function pauseStaking(uint256 _contract_num, bool _state) public onlyAdmins {
        if(_contract_num == 0) {
            pausedStake_A = _state;
        }
        else if(_contract_num == 1){
            pausedStake_B = _state;
        }
        else if(_contract_num == 2){
            pausedStake_C = _state;
        }
    }

    /**
     * @dev User can stake NFTs they own to earn rewards over time.
     * Note: User must set this contract as approval for all on the parentNFT contracts in order to stake NFTs.
     */
    function stake(uint[] memory _tokenIDs, uint256 _contract_num) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        if(_tokenIDs.length == 1){
            stakeOne(_tokenIDs[0], _contract_num);
        }
        else{
            stakeMultiple(_tokenIDs, _contract_num);
        }
    }

    function stakeOne(uint256 _tokenID, uint256 _contract_num) private {
        if(_contract_num == 0){
            require(pausedStake_A != true, "Contract A Staking Paused");
            require(tokenOwnerOf_A[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_A.safeTransferFrom(msg.sender, address(this), _tokenID);
            tokenOwnerOf_A[_tokenID] = msg.sender;
            tokenStakedAt_A[_tokenID] = block.timestamp;
        }
        else if(_contract_num == 1){
            require(pausedStake_B != true, "Contract B Staking Paused");
            require(tokenOwnerOf_B[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_B.safeTransferFrom(msg.sender, address(this), _tokenID);
            tokenOwnerOf_B[_tokenID] = msg.sender;
            tokenStakedAt_B[_tokenID] = block.timestamp;
        }
        else if(_contract_num == 2){
            require(pausedStake_C != true, "Contract B Staking Paused");
            require(tokenOwnerOf_C[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_C.safeTransferFrom(msg.sender, address(this), _tokenID);
            tokenOwnerOf_C[_tokenID] = msg.sender;
            tokenStakedAt_C[_tokenID] = block.timestamp;
        }
    }

    function stakeMultiple(uint[] memory _tokenIDs, uint256 _contract_num) private {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            stakeOne(_tokenID, _contract_num);
        }
    }

    /**
     * @dev User can check estimated rewards gained so far from an address that staked an NFT.
     * Note: The staker address must have an NFT currently staked.
     */
    function estimateRewards(uint[] memory _tokenIDs, uint256 _contract_num) public view returns (uint256) {
        uint256 timeElapsed;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            if(_contract_num == 0){
                require(tokenOwnerOf_A[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                timeElapsed += (block.timestamp - tokenStakedAt_A[_tokenID]);
            }
            else if(_contract_num == 1){
                require(tokenOwnerOf_B[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                timeElapsed += (block.timestamp - tokenStakedAt_B[_tokenID]);
            }
            else if(_contract_num == 2){
                require(tokenOwnerOf_C[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                timeElapsed += (block.timestamp - tokenStakedAt_C[_tokenID]);
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
    function unstake(uint[] memory _tokenIDs, uint256 _contract_num) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        require(isOwnerOfAllStaked(msg.sender, _contract_num, _tokenIDs), "CANNOT UNSTAKE");

        uint256 reward = estimateRewards(_tokenIDs, _contract_num);

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            if(_contract_num == 0){
                parentNFT_A.safeTransferFrom(address(this), msg.sender, _tokenID);
                delete tokenOwnerOf_A[_tokenID];
                delete tokenStakedAt_A[_tokenID];
            }
            else if(_contract_num == 1){
                parentNFT_B.safeTransferFrom(address(this), msg.sender, _tokenID);
                delete tokenOwnerOf_B[_tokenID];
                delete tokenStakedAt_B[_tokenID];
            }
            else if(_contract_num == 2){
                parentNFT_C.safeTransferFrom(address(this), msg.sender, _tokenID);
                delete tokenOwnerOf_C[_tokenID];
                delete tokenStakedAt_C[_tokenID];
            }
        }
        _mint(msg.sender, reward); // Minting the reward tokens gained for staking
    }

    /**
     * @dev Allows Owner or Project Leader to set the parentNFT contracts to a specified address.
     * WARNING: Double check all users NFTs are unstaked before setting a new address
     */
    function setStakingContract(uint256 _contract_num, address _contractAddress) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");

        if(_contract_num == 0){
            parentNFT_A = IERC721(_contractAddress); // set the main NFT contract (parentNFT_A)
        }
        else if(_contract_num == 1){
            parentNFT_B = IERC721(_contractAddress); // set the main NFT contract (parentNFT_B)
        }
        else if(_contract_num == 2) {
            parentNFT_C = IERC721(_contractAddress); // set the main NFT contract (parentNFT_C)
        }
    }

    /**
     * @dev Returns the owner address of a specific token staked
     * Note: If address returned is 0x0000000000000000000000000000000000000000 token is not staked.
     */
    function getTokenOwnerOf(uint256 _contract_num, uint256 _tokenID) public view returns(address){
        if(_contract_num == 0){
            return tokenOwnerOf_A[_tokenID];
        }
        else if(_contract_num == 1){
            return tokenOwnerOf_B[_tokenID];
        }
        else if(_contract_num == 2){
            return tokenOwnerOf_C[_tokenID];
        }
    }

    function isOwnerOfAllStaked(address _holder, uint256 _contract_num, uint[] memory _tokenIDs) public view returns(bool){
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];

            if(getTokenOwnerOf(_contract_num, _tokenID) == _holder){
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
    function getStakedAt(uint256 _contract_num, uint256 _tokenID) public view returns(uint256){
        if(_contract_num == 0){
            return tokenStakedAt_A[_tokenID];
        }
        else if(_contract_num == 1){
            return tokenStakedAt_B[_tokenID];
        }
        else if(_contract_num == 2){
            return tokenStakedAt_C[_tokenID];
        }
    }

    /**
     * @dev Allows Admins to mint an amount of tokens to a specified address.
     * Note: _amount must be in WEI use https://etherscan.io/unitconverter for conversions.
     */
    function mintTokens(address _to, uint256 _amount) external onlyAdmins {
        _mint(_to, _amount); // Minting Tokens
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