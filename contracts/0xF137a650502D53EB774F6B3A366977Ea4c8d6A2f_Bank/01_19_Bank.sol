// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Pausable.sol";
import "./Billionaire.sol";
import "./Cyborg.sol";

contract Bank is IERC721Receiver, Pausable {
    struct Token {
        uint256 nft_party;
        uint256 nft_cybork;
        uint256 staking_time;
    }
    uint256 public totalPoints;
    uint256 public totalPartyApe;
    uint256 public totalCyborg;
    uint256 public totalReward;

    address payable addressParty;
    address public addressCybork;

    mapping(uint256 => uint256) public indexTokenParty;
    mapping(uint256 => uint256) public idTokenCybork;
    mapping(uint256 => address) public userTokenParty;
    mapping(address => uint256) public userReward;
    mapping(address => uint256) public userPoints;
    mapping(address => bool) public isUser;
    mapping(address => Token[]) public stakedToken;

    address[] public users;

    Billionaire partyContract;
    Cyborg cyborkContract;

    constructor(address payable _addressParty, address _addressCybork) {
        require(
            _addressParty != address(0),
            "Bank Billionaire Club:  party contract address is Zero address"
        );
        require(
            _addressCybork != address(0),
            "Bank Billionaire Club:  cybork contract address is Zero address"
        );

        addressParty = payable(_addressParty);
        partyContract = Billionaire(addressParty);
        addressCybork = _addressCybork;
        cyborkContract = Cyborg(addressCybork);
    }

    function getNFT(address _user) public view returns (Token[] memory) {
        return stakedToken[_user];
    }

    function stakeNFT(uint256 _tokenParty, uint256 _tokenCybork)
        external
        whenNotPaused
    {
        require(
            (partyContract.ownerOf(_tokenParty) == msg.sender),
            "Billionaire Club: Caller is not the owner of the Party Ape token"
        );
        require(
            (cyborkContract.ownerOf(_tokenCybork) == msg.sender),
            "Cyborgs Billionaire Club: Caller is not the owner of the Cybork token"
        );
        require(
            (cyborkContract.isTokenMerged(_tokenParty) == true),
            "Cyborgs Billionaire Club: Party Ape token is not merged "
        );

        stakedToken[msg.sender].push(
            Token(_tokenParty, _tokenCybork, block.timestamp)
        );
        indexTokenParty[_tokenParty] = stakedToken[msg.sender].length -1;
        idTokenCybork[_tokenParty] = _tokenCybork;
        userTokenParty[_tokenParty] = msg.sender;
        totalPartyApe = totalPartyApe + 1;
        totalCyborg = totalCyborg + 1;

        partyContract.safeTransferFrom(msg.sender, address(this), _tokenParty);
        cyborkContract.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenCybork
        );
        if (isUser[msg.sender] == false) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }
    }

    function calculatePoints() external onlyOwner {
        require(totalPoints == 0, "total points is zero");
        address _user;
        for (uint256 i = 0; i < users.length; i++) {
            _user = users[i];
            require(
                _user != address(0),
                "Bank Billionaire Club:  user is Zero address"
            );
            require(
                userPoints[_user] == 0,
                "Bank Billionaire Club:  user points is not zero"
            );
            for (uint256 j = 0; j < stakedToken[_user].length; j++) {
                if (stakedToken[_user][j].staking_time == 0) {
                    continue;
                }
                userPoints[_user] =
                    userPoints[_user] +
                    (block.timestamp - stakedToken[_user][j].staking_time);
            }
            totalPoints = totalPoints + userPoints[_user];
        }
    }

    function calculateRewards() external onlyOwner {
        require(
            address(this).balance > 0,
            "Bank Billionaire Club:  contract balance is Zero"
        );
        address _user;
        for (uint256 i = 0; i < users.length; i++) {
            _user = users[i];
            userReward[_user] =
                userReward[_user] +
                (address(this).balance * userPoints[_user]) /
                totalPoints;
            userPoints[_user] = 0;
            totalReward = totalReward + userReward[_user];
        }
        totalPoints = 0;
    }

    function claimRewards(uint256 _amount) external {
        require(
            msg.sender != address(0),
            "Bank Billionaire Club: caller is Zero address"
        );
        require(_amount > 0, "Bank Billionaire Club: _amount is zero");
        require(
            _amount <= userReward[msg.sender],
            "Bank Billionaire Club: _amount excedes the user rewards"
        );
        userReward[msg.sender] = userReward[msg.sender] - _amount;
        totalReward = totalReward - _amount;

        payable(msg.sender).transfer(_amount);
    }

    function unstakeNFT(uint256 _tokenParty) external {
        require(
            partyContract.ownerOf(_tokenParty) == address(this),
            "Bank Billionaire Club: nft is not staked"
        );
        address _user = userTokenParty[_tokenParty];
        require(
            _user == msg.sender,
            "Bank Billionaire Club: caller is not the owner"
        );
        totalPartyApe = totalPartyApe - 1;
        totalCyborg = totalCyborg - 1;
        partyContract.safeTransferFrom(address(this), msg.sender, _tokenParty);
        cyborkContract.safeTransferFrom(
            address(this),
            msg.sender,
            idTokenCybork[_tokenParty]
        );
          uint256 _index = indexTokenParty[_tokenParty];
          stakedToken[msg.sender][_index].nft_party = 0;
          stakedToken[msg.sender][_index].nft_cybork = 0;
          stakedToken[msg.sender][_index].staking_time = 0;
    }

    function receiveEher() external payable {}

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Bank Billionaire Club: amount is zero");
        require(
            address(this).balance >= _amount,
            "Bank Billionaire Club: insufficient contract balance"
        );
        payable(msg.sender).transfer(_amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}