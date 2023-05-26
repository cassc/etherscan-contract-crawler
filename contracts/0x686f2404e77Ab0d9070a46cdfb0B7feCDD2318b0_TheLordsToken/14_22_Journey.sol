// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../shared/interfaces/RealmsToken.sol";
import "../shared/interfaces/LordsToken.sol";

contract Journey is ERC721Holder, Ownable, ReentrancyGuard {
    event StakeRealms(uint256[] tokenIds, address player);
    event UnStakeRealms(uint256[] tokenIds, address player);

    mapping(address => uint256) epochClaimed;
    mapping(uint256 => address) ownership;
    mapping(address => mapping(uint256 => uint256)) public realmsStaked;

    LordsToken lordsToken;
    RealmsToken realmsToken;

    // contracts
    address bridge;

    // consts
    uint256 lordsPerRealm;
    uint256 genesis;
    uint256 epoch;

    bool paused;

    constructor(
        uint256 _lordsPerRealm,
        uint256 _epoch,
        address _realmsAddress,
        address _lordsToken
    ) {
        genesis = block.timestamp;
        lordsPerRealm = _lordsPerRealm;
        epoch = _epoch;

        lordsToken = LordsToken(_lordsToken);
        realmsToken = RealmsToken(_realmsAddress);

        paused = false;
    }

    /**
     * @notice Set's Lords issurance in gwei per staked realm
     */
    function lordsIssurance(uint256 _new) external onlyOwner {
        lordsPerRealm = _new * 10**18; // converted into decimals
    }

    function updateRealmsAddress(address _newRealms) external onlyOwner {
        realmsToken = RealmsToken(_newRealms);
    }

    function updateLordsAddress(address _newLords) external onlyOwner {
        lordsToken = LordsToken(_newLords);
    }

    function updateEpochLength(uint256 _newEpoch) external onlyOwner {
        epoch = _newEpoch;
    }

    function setBridge(address _newBridge) external onlyOwner {
        bridge = _newBridge;
    }

    function pauseContract(bool _state) external onlyOwner {
        paused = _state;
    }

    /**
     * @notice Set's epoch to epoch * 1 hour.
     */
    function _epochNum() internal view returns (uint256) {
        return (block.timestamp - genesis) / (epoch * 3600); // hours
        // return 5;
    }

    /**
     * @notice Boards the Ship (Stakes). Sets ownership of Token to Staker. Transfers NFT to Contract. Set's epoch date, Set's number of Realms staked in the Epoch.
     * @param _tokenIds Ids of Realms
     */
    function boardShip(uint256[] memory _tokenIds)
        external
        notPaused
        nonReentrant
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                realmsToken.ownerOf(_tokenIds[i]) == msg.sender,
                "NOT_OWNER"
            );
            ownership[_tokenIds[i]] = msg.sender;

            realmsToken.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }

        if (lordsAvailable(msg.sender) == 0) {
            epochClaimed[msg.sender] = _epochNum();
        }

        realmsStaked[msg.sender][_epochNum()] =
            realmsStaked[msg.sender][_epochNum()] +
            uint256(_tokenIds.length);

        emit StakeRealms(_tokenIds, msg.sender);
    }

    /**
     * @notice Exits Ship, and transfers all Realms back to owner.
     * @param _tokenIds Ids of Realms
     */
    function exitShip(uint256[] memory _tokenIds)
        external
        notPaused
        nonReentrant
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownership[_tokenIds[i]] == msg.sender, "NOT_OWNER");

            ownership[_tokenIds[i]] = address(0);

            realmsToken.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
        }

        realmsStaked[msg.sender][_epochNum()] =
            realmsStaked[msg.sender][_epochNum()] -
            uint256(_tokenIds.length);

        emit UnStakeRealms(_tokenIds, msg.sender);
    }

    /**
     * @notice Claims all available Lords for Owner.
     */
    function claimLords() external notPaused nonReentrant {
        uint256 totalClaimable;
        uint256 totalRealms;

        require(_epochNum() > 1, "GENESIS_epochNum");

        // loop over epochs, sum up total claimable staked lords per epoch
        for (uint256 i = epochClaimed[msg.sender]; i < _epochNum(); i++) {
            totalRealms += realmsStaked[msg.sender][i];
            totalClaimable =
                totalClaimable +
                realmsStaked[msg.sender][i] *
                (_epochNum() - i);
        }

        // set totalRealms staked in latest epoch so loop doesn't have to iterate again
        realmsStaked[msg.sender][_epochNum()] = totalRealms;

        // set epoch claimed to current
        epochClaimed[msg.sender] = _epochNum();

        require(totalClaimable > 0, "NOTHING_TO_CLAIM");

        // available lords * total realms staked per period
        uint256 lords = lordsPerRealm * totalClaimable;

        lordsToken.approve(address(this), lords);

        lordsToken.transferFrom(address(this), msg.sender, lords);
    }

    /**
     * @notice Lords available for the player.
     */
    function lordsAvailable(address _player)
        public
        view
        returns (uint256 lords)
    {
        uint256 totalClaimable;

        for (uint256 i = epochClaimed[_player]; i < _epochNum(); i++) {
            totalClaimable =
                totalClaimable +
                realmsStaked[_player][i] *
                (_epochNum() - i);
        }

        lords = lordsPerRealm * totalClaimable;
    }

    /**
     * @notice Called only by future Bridge contract to withdraw the Realms
     * @param _tokenIds Ids of Realms
     */
    function bridgeWithdraw(address _player, uint256[] memory _tokenIds)
        public
        onlyBridge
        nonReentrant
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ownership[_tokenIds[i]] = address(0);

            realmsToken.safeTransferFrom(address(this), _player, _tokenIds[i]);
        }

        realmsStaked[_player][_epochNum()] =
            realmsStaked[_player][_epochNum()] -
            uint256(_tokenIds.length);

        emit UnStakeRealms(_tokenIds, _player);
    }

    function withdrawAllLords(address _destination) public onlyOwner {
        uint256 balance = lordsToken.balanceOf(address(this));

        lordsToken.approve(address(this), balance);
        lordsToken.transferFrom(address(this), _destination, balance);
    }

    modifier onlyBridge() {
        require(msg.sender == bridge, "NOT_THE_BRIDGE");
        _;
    }
    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }

    function checkOwner(uint256 _tokenId) public view returns (address) {
        return ownership[_tokenId];
    }

    function getEpoch() public view returns (uint256) {
        return _epochNum();
    }

    function getLordsAddress() public view returns (address) {
        return address(lordsToken);
    }

    function getRealmsAddress() public view returns (address) {
        return address(realmsToken);
    }

    function getEpochLength() public view returns (uint256) {
        return epoch;
    }

    function getLordsIssurance() public view returns (uint256) {
        return lordsPerRealm;
    }

    function getNumberRealms(address _player) public view returns (uint256) {
        uint256 totalRealms;

        for (uint256 i = epochClaimed[_player]; i <= _epochNum(); i++) {
            totalRealms += realmsStaked[_player][i];
        }
        return totalRealms;
    }
}