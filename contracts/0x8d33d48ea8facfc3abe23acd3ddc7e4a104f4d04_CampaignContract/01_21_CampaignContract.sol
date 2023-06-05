// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './RedeemableToken.sol';

contract CampaignContract is ReentrancyGuard, Ownable {
    string public name;

    struct CampaignTrack {
        uint32 campaignId;
        uint256 tokenId;
        uint256 price;
        uint256 ethPrice;
        uint256 maxTokens;
        uint256 maxTokensPerUser; // 0 means unlimited
        IERC20[] paymentTokens;
        bytes32 merkleRoot;
        uint32 startTime;
        uint32 endTime;
    }

    mapping(uint256 => CampaignTrack) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public userPurchases;
    mapping(uint256 => uint256) public tokensMinted;

    RedeemableToken token;
    uint32 public campaignNum;

    event UpdateMerkleRoot(uint32 indexed campaignId, bytes32 merkleRoot);
    event UpdatePaymentTokens(
        uint32 indexed campaignId,
        IERC20[] paymentTokens
    );

    event BuyToken(address indexed buyer, uint256 tokenId, uint32 campaignId);
    event AddTrack(uint32 indexed campaignId, CampaignTrack campaign);

    constructor(string memory _name, RedeemableToken _token) {
        name = _name;
        token = _token;
    }

    function buyTokenWithEth(
        uint32 _campaignId,
        uint256 _amount,
        bytes32[] memory _proof
    ) public payable nonReentrant {
        require(_campaignId < campaignNum, 'Invalid campaign ID');
        CampaignTrack storage campaign = campaigns[_campaignId];

        require(_validateBuyToken(_campaignId, _amount), 'invalid parameters');

        // no whitelist, everyone can mint
        if (campaign.merkleRoot == 0) {
            _mintTokenWithEth(_amount, _campaignId, msg.sender);
        } else {
            require(
                verify(msg.sender, campaign.merkleRoot, _proof),
                'You are not authorized to purchase a token'
            );
            _mintTokenWithEth(_amount, _campaignId, msg.sender);
        }

        emit BuyToken(msg.sender, campaign.tokenId, campaign.campaignId);
    }

    function buyToken(
        uint32 _campaignId,
        IERC20 _paymentToken,
        uint256 _amount,
        bytes32[] memory _proof
    ) public nonReentrant {
        require(_campaignId < campaignNum, 'Invalid campaign ID');
        CampaignTrack storage campaign = campaigns[_campaignId];

        require(_validateBuyToken(_campaignId, _amount), 'invalid parameters');

        require(
            isSupportedPaymentToken(_campaignId, _paymentToken),
            'Payment token is not supported'
        );

        // no whitelist, everyone can mint
        if (campaign.merkleRoot == 0) {
            _mintToken(_paymentToken, _amount, _campaignId, msg.sender);
        } else {
            require(
                verify(msg.sender, campaign.merkleRoot, _proof),
                'You are not authorized to purchase a token'
            );
            _mintToken(_paymentToken, _amount, _campaignId, msg.sender);
        }

        emit BuyToken(msg.sender, campaign.tokenId, campaign.campaignId);
    }

    function updateMerkleRoot(uint32 _campaignId, bytes32 _merkleRoot)
        public
        onlyOwner
    {
        require(_campaignId < campaignNum, 'Invalid campaign ID');
        CampaignTrack storage campaign = campaigns[_campaignId];
        campaign.merkleRoot = _merkleRoot;

        emit UpdateMerkleRoot(_campaignId, _merkleRoot);
    }

    function updatePaymentTokens(
        uint32 _campaignId,
        IERC20[] memory _paymentTokens
    ) public onlyOwner {
        require(_campaignId < campaignNum, 'Invalid campaign ID');
        require(_paymentTokens.length > 0, 'Minimum one payment token');

        CampaignTrack storage campaign = campaigns[_campaignId];
        campaign.paymentTokens = _paymentTokens;

        emit UpdatePaymentTokens(_campaignId, _paymentTokens);
    }

    function addTrack(
        uint256 tokenId,
        uint256 price,
        uint256 ethPrice,
        uint256 maxTokens,
        uint256 maxTokensPerUser,
        IERC20[] memory paymentTokens,
        bytes32 merkleRoot,
        uint32 startTime,
        uint32 endTime
    ) public {
        uint256 currentTimestamp = block.timestamp;
        CampaignTrack memory campaign = CampaignTrack(
            campaignNum,
            tokenId,
            price,
            ethPrice,
            maxTokens,
            maxTokensPerUser,
            paymentTokens,
            merkleRoot,
            startTime,
            endTime
        );

        require(
            startTime > currentTimestamp &&
                endTime > currentTimestamp &&
                endTime > startTime,
            'Invalid campaign schedule'
        );

        require(
            price == 0 || (price > 0 && paymentTokens.length > 0),
            'Minimum one payment token'
        );

        require(maxTokens > 0, 'Need to specify max tokens');

        campaigns[campaignNum] = campaign;
        campaignNum += 1;

        emit AddTrack(campaignNum - 1, campaign);
    }

    function verify(
        address _account,
        bytes32 _merkleRoot,
        bytes32[] memory _proof
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProof.verify(_proof, _merkleRoot, leaf);
    }

    function isSupportedPaymentToken(uint32 _campaignId, IERC20 _paymentToken)
        public
        view
        returns (bool)
    {
        require(_campaignId < campaignNum, 'Invalid campaign ID');
        CampaignTrack memory campaign = campaigns[_campaignId];
        for (uint32 i = 0; i < campaign.paymentTokens.length; i++) {
            if (campaign.paymentTokens[i] == _paymentToken) {
                return true;
            }
        }

        return false;
    }

    function _validateBuyToken(uint32 _campaignId, uint256 _amount)
        private
        returns (bool)
    {
        require(_campaignId < campaignNum, 'Invalid campaign ID');
        CampaignTrack memory campaign = campaigns[_campaignId];

        uint256 currentTimestamp = block.timestamp;

        userPurchases[_campaignId][msg.sender] += _amount;
        tokensMinted[_campaignId] += _amount;

        require(
            campaign.maxTokensPerUser == 0 ||
                userPurchases[_campaignId][msg.sender] <=
                campaign.maxTokensPerUser,
            'Exceeding purchase limit'
        );

        require(
            currentTimestamp > campaign.startTime &&
                currentTimestamp < campaign.endTime,
            'Campaign is not running'
        );

        require(
            tokensMinted[_campaignId] <= campaign.maxTokens,
            'Maximum tokens minted'
        );

        return true;
    }

    function _mintTokenWithEth(
        uint256 _amount,
        uint256 _campaignId,
        address _account
    ) private {
        CampaignTrack memory campaign = campaigns[_campaignId];

        require(
            msg.value >= campaign.ethPrice * _amount,
            'Insufficient payment'
        );

        token.mint(_account, campaign.tokenId, _amount);
    }

    function _mintToken(
        IERC20 _paymentToken,
        uint256 _amount,
        uint256 _campaignId,
        address _account
    ) private {
        CampaignTrack memory campaign = campaigns[_campaignId];

        require(
            _paymentToken.transferFrom(
                msg.sender,
                address(this),
                campaign.price * _amount
            ),
            'Transfer failed, check allowance'
        );

        token.mint(_account, campaign.tokenId, _amount);
    }

    function withdraw(IERC20 _token) public onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function withdrawEth() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}