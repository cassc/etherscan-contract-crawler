// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/tokens/ERC721.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import 'chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import './Helpers.sol';

error NonExistentTokenURI();
error WithdrawTransfer();
error ProtectionStillActive();
error LiquidationNotFound();

interface IDirectLoanBase {
    function loanRepaidOrLiquidated(uint32) external view returns (bool);
}

/**
 * @title Gradient Protection (v0.1) contract
 * @author cairoeth
 * @dev ERC721 contract from which NFTs are minted to represent loan protection.
 **/
contract Protection is ERC721, Ownable, ReentrancyGuard, Helpers, ChainlinkClient {
    using Strings for uint256;
    using Chainlink for Chainlink.Request;
    bytes32 private constant jobId = "9303ebb8365e472eb9a1505a3cc42317";
    uint256 private constant fee = 4500000000000000000; /// 4.5 LINK
    address private nftfiAddress;
    string public baseURI;

    struct LoanProtection {
        uint256 stake;
        uint256 lowerBound;
        uint256 upperBound;
        uint256 startingUnix;
        uint256 expiryUnix;
        uint256 collateralIdToProtection;
        address collateralContractToProtection;
    }

    mapping(bytes32 => uint32) private requestToProtection;
    mapping(uint32 => LoanProtection) private protectionData;

    event RequestedPrice(bytes32 indexed requestId, uint256 price);

    constructor() ERC721("Gradient Protection", "PROTECTION") {
        setChainlinkToken(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        setChainlinkOracle(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434);
        baseURI = "https://app.gradient.city/metadata/";
        nftfiAddress = 0x33e75763F3705252775C5AEEd92E5B4987622f44;
    }

    /**
    * @notice Mints ERC721 token that represents loan protection
    * @param _recipient Receiver address of the protection (lender)
    * @param _nftfiId ID of the NFTfi Promissory Note
    * @param _lowerBoundVal Lower boundary of the protection
    * @param _upperBoundVal Upper boundary of the protection
    * @param _startingUnix Unix timestamp when loan starts (NFTfi)
    * @param _expiryUnix Unix timmestamp when loan expires (NFTfi)    
    * @param _collateralContract Contract address of loan collateral
    * @param _collateralId Token ID of loan collateral    
    **/
    function mintProtection(address _recipient, uint32 _nftfiId, uint256 _lowerBoundVal, uint256 _upperBoundVal, uint256 _startingUnix, uint256 _expiryUnix, address _collateralContract, uint256 _collateralId) public payable onlyOwner {
        /// msg.value value: amount of funds (wei) staked to cover losses of any collateral liquidation in case the borrower defaults
        _safeMint(_recipient, _nftfiId);
        protectionData[_nftfiId] = LoanProtection({
            stake: msg.value,
            lowerBound: _lowerBoundVal,
            upperBound: _upperBoundVal,
            startingUnix: _startingUnix,
            expiryUnix: _expiryUnix + 1 days,
            collateralIdToProtection: _collateralId,
            collateralContractToProtection: _collateralContract
        });
    }

    /**
    * @notice Returns the URL of a token's metadata
    * @param tokenId Token ID
    **/
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_ownerOf[tokenId] != address(0), "Non-existent token URI");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
    * @notice Triggers the protection after loan reaches maturity
    * @param _nftfiId is the id of the NFTfi Promissory Note/protection NFT 
    **/
    function triggerProtection(uint32 _nftfiId) external nonReentrant {
        require(_ownerOf[_nftfiId] != address(0), "Protection does not exist");
        require(IDirectLoanBase(nftfiAddress).loanRepaidOrLiquidated(_nftfiId));

        /// Closes a expired protection when the borrower payed back or when the lender wants to keep the collateral
        if (block.timestamp > protectionData[_nftfiId].expiryUnix) {
            uint256 payback = protectionData[_nftfiId].stake;
            protectionData[_nftfiId].stake = 0;
            _burn(_nftfiId);

            /// Return stake
            (bool transferTx, ) = owner().call{value: payback}("");
            require(transferTx, "Payback transfer failed.");
        }
        else {
            requestPrice(
                protectionData[_nftfiId].collateralContractToProtection,
                protectionData[_nftfiId].collateralIdToProtection,
                protectionData[_nftfiId].startingUnix,
                _nftfiId);
        }
    }

    /**
    * @dev Creates a Chainlink request to retrieve API response to validate collateral liquidation on OpenSea
    * @param _contractAddress Contract address of loan collateral
    * @param _tokenId Token ID of loan collateral
    * @param _startingUnix Unix timestamp when loan starts (NFTfi)
    * @param _nftfiId Token ID of ERC721 protection 
    **/
    function requestPrice(address _contractAddress, uint256 _tokenId, uint256 _startingUnix, uint32 _nftfiId) private {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillValue.selector);

        /// Set the URL to perform the GET request on -- will change!
        string memory s = string.concat('http://disestevez.pythonanywhere.com/', _toAsciiString(_contractAddress));
        s = string.concat(s, "/");
        s = string.concat(s, Strings.toString(_tokenId));
        s = string.concat(s, "/");
        s = string.concat(s, Strings.toString(_startingUnix));
        req.add('get', s);

        req.add('path', 'price'); /// Chainlink nodes 1.0.0 and later support this format

        /// Multiply 1
        int256 timesAmount = 1;
        req.addInt('times', timesAmount);

        /// Sends the request
        bytes32 sendRequest = sendChainlinkRequest(req, fee);
        requestToProtection[sendRequest] = _nftfiId;
    }

    /**
    * @notice Runs the protection using the data from OpenSea
    * @param _nftfiId is the id of the NFTfi Promissory Note/protection NFT 
    **/
    function activateProtection(uint32 _nftfiId, uint256 _liquidationFunds) private {
         /// Check to prevent oracle manipulation by external calls 
        require(_ownerOf[_nftfiId] != address(0), "Protection does not exist");

        /// Closes a protection after the collateral has been liquidated by covering any losses
        /// The Oracle returns a higher value than 2**256 - 7 when a Dutch auction is not found
        if (_liquidationFunds < 2**256 - 7) {
            /// Option A: The collateral is liquidated at a price above the upper-bound of the protection 
            if (_liquidationFunds > protectionData[_nftfiId].upperBound) {
                uint256 payback = protectionData[_nftfiId].stake;
                protectionData[_nftfiId].stake = 0;
                _burn(_nftfiId);

                /// Return stake
                (bool transferTx, ) = owner().call{value: payback}("");
                require(transferTx, "Payback transfer failed.");
            }
            /// Option B: The collateral is liquidated at a price between the bounds of the protection
            else if (protectionData[_nftfiId].lowerBound < _liquidationFunds && _liquidationFunds < protectionData[_nftfiId].upperBound) {
                address receiverProtection = _ownerOf[_nftfiId];
                uint256 losses = protectionData[_nftfiId].upperBound - _liquidationFunds;
                uint256 payback = protectionData[_nftfiId].stake - losses;
                protectionData[_nftfiId].stake = 0;
                _burn(_nftfiId);

                /// Return remaining stake, if any.
                (bool transferTx1, ) = owner().call{value: payback}("");
                require(transferTx1, "Payback transfer failed.");

                /// Return all $ from the liquidation to protection owner and cover lossses
                (bool transferTx2, ) = receiverProtection.call{value: losses}("");
                require(transferTx2, "Protection transfer failed.");
            }
            /// Option C: The collateral is liquidated at a price below the lower-bound of the protection
            else if (_liquidationFunds < protectionData[_nftfiId].lowerBound) {
                address receiverProtection = _ownerOf[_nftfiId];
                uint256 payback = protectionData[_nftfiId].stake;
                protectionData[_nftfiId].stake = 0;
                _burn(_nftfiId);

                /// Return all $ from the liquidation and protection to protection owner
                (bool transferTx, ) = receiverProtection.call{value: payback}("");
                require(transferTx, "Protection transfer failed.");
            }
        }
        else {
            revert LiquidationNotFound();
        }
    }

    /**
    * @dev Recieves oracle response in the form of uint256
    * @param _requestId Chainlink request ID
    * @param _price fetched price (wei)
    **/
    function fulfillValue(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        emit RequestedPrice(_requestId, _price);
        activateProtection(requestToProtection[_requestId], _price);
    }

    /**
    * @notice Sets the NFTfi address
    * @param _address is the NFTfi main smart contract address
    **/
    function setNFTfiAddress(address _address) external onlyOwner {
       nftfiAddress = _address;
    }

    /**
    * @notice Allows to withdraw LINK tokens
    **/
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(owner(), link.balanceOf(address(this))), 'Unable to transfer');
    }
}