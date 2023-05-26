// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721Enumerable, Ownable {
		using Strings for uint256;

		uint256 public constant TOKEN_PRICE = 60000000000000000; // 0.06 ETH
		uint16 public constant MAX_TOKEN_COUNT = 10000;
		uint16 public constant MAX_SINGLE_MINT_COUNT = 10;

		bool public m_bSalesEnabled = true;
    uint16 private m_unCurrTokenId = 0;

		address payable private m_adrSaleReceiver = payable(0);
		uint16 public MintedTokenTotal = 0;

		struct BurnLedgerItem
		{
			address payable adrOwner;
			uint16 unBurntTokenCount;
		}

		mapping(uint16 => BurnLedgerItem) m_mapBurnLedger;
		mapping(address => uint16) m_mapAddressToBurnItemIndex;
		uint16 private m_unBurnItemCount = 0;
		uint16 public BurntTokenTotal = 0;
		uint256 public BurnPayoutTotal = 0;
		uint16 public FreeTokenThreshold = MAX_SINGLE_MINT_COUNT + 1;
		uint16 private m_unShadowStartIndex = 0;

		bool public m_bLicenseLocked = false;
		string public m_strLicense;
		bool m_bLock = false;

		string public PROVENANCE = "";

    constructor(string memory _name, string memory _symbol) 
			ERC721(_name, _symbol)
		{

    }

		// @notice Will receive any eth sent to the contract
		receive () external payable {

		}

		function getSaleReceiver() public view onlyOwner returns(address)
		{
			return m_adrSaleReceiver;
		}

		function setSaleReceiver(address payable adrSaleReciever) public onlyOwner
		{
			m_adrSaleReceiver = adrSaleReciever;
		}

		function reserveTokens(uint16 unCount, address adrReserveDest) public onlyOwner
		{
			require(m_unCurrTokenId + unCount < MAX_TOKEN_COUNT, "ERC721Tradable: Token supply has been exhausted.");
			for(uint16 i = 0; i < unCount; ++i)
			{
				uint16 newTokenId = getCurrTokenId();
				incrementTokenId();
				_safeMint(adrReserveDest, newTokenId);
			}
		}

		function areSalesEnabled() public view returns(bool)
		{
			return m_bSalesEnabled;
		}

		function setSalesEnabled(bool bEnabled) public onlyOwner
		{
			m_bSalesEnabled = bEnabled;
		}

    function mintTokens(uint16 unCount) public payable {

				require(!m_bLock, "ERC721Tradable: Contract locked to prevent reentrancy");
				m_bLock = true;

				require(m_bSalesEnabled, "ERC721Tradable: Minting is currently unavailable.");
				require(unCount <= MAX_SINGLE_MINT_COUNT, "ERC721Tradable: You may only mint up to 10 tokens at a time.");
				require(msg.value >= TOKEN_PRICE * unCount, "ERC721Tradable: Ether value sent is less than total token price.");

				// Provide a free token 
				if(unCount >= FreeTokenThreshold && m_unCurrTokenId + unCount + 1 < MAX_TOKEN_COUNT)
					unCount++;

				require(m_unCurrTokenId + unCount < MAX_TOKEN_COUNT, "ERC721Tradable: Token supply has been exhausted.");
				require(m_adrSaleReceiver != address(0), "ERC721Tradable: Payment collection is not set up.");

				for(uint16 i = 0; i < unCount; ++i)
				{
					uint16 newTokenId = getCurrTokenId();
					incrementTokenId();
        	_safeMint(msg.sender, newTokenId);
				}

				MintedTokenTotal += unCount;

				m_bLock = false;

				(bool bFinalSuccess, ) = m_adrSaleReceiver.call{value: msg.value}("");
				require(bFinalSuccess, "ERC721Tradable: Transfer to sale receiver failed.");
    }

		function burnToken(uint16 unTokenID) public 
		{
			require(!m_bLock, "ERC721Tradable: Contract locked to prevent reentrancy");
			m_bLock = true;

			require(ownerOf(unTokenID) == msg.sender, "ERC721Tradable: Surrender caller is not owner of token.");
			_burn(unTokenID);

			uint16 unSenderItemIndex = m_mapAddressToBurnItemIndex[msg.sender];
			if(unSenderItemIndex > 0)
			{
				m_mapBurnLedger[unSenderItemIndex].unBurntTokenCount++;
			}
			else
			{
				uint16 unNewItemIndex = m_unBurnItemCount + 1;
				m_mapAddressToBurnItemIndex[msg.sender] = unNewItemIndex;
				m_mapBurnLedger[unNewItemIndex].adrOwner = payable(msg.sender);
				m_mapBurnLedger[unNewItemIndex].unBurntTokenCount = 1;

				m_unBurnItemCount++;
			}

			BurntTokenTotal++;

			m_bLock = false;
		}

		function doAllBurnPayouts() public payable onlyOwner
		{
			require(m_unBurnItemCount > 0, "ERC721Tradable: There are no burn records.");
			require(BurntTokenTotal > 0, "ERC721Tradable: There are no burnt tokens.");

			uint256 valueForBurns = address(this).balance / 10.0;
			BurnPayoutTotal += valueForBurns;
			uint256 unValuePer = valueForBurns / BurntTokenTotal;
			
			for(uint16 i = 1; i <= m_unBurnItemCount; ++i)
			{
				(bool bCurrSuccess, ) = m_mapBurnLedger[i].adrOwner.call{
					value: unValuePer * m_mapBurnLedger[i].unBurntTokenCount
				}("");

				require(bCurrSuccess, "ERC721Tradable: Transfer to burn holder failed.");
			}

			(bool bFinalSuccess, ) = m_adrSaleReceiver.call{value: address(this).balance}("");
			require(bFinalSuccess, "ERC721Tradable: Transfer to sale receiver failed.");

		}

		function getBurnItemCount() public view returns (uint16)
		{
			return m_unBurnItemCount;
		}

		function burnBalanceOf(address owner) public view returns (uint16)
		{
			uint16 unOwnerItemIndex = m_mapAddressToBurnItemIndex[owner];
			return m_mapBurnLedger[unOwnerItemIndex].unBurntTokenCount;
		}

		function burnBalanceOfIndex(uint16 unIndex) public view returns (uint16)
		{
			return m_mapBurnLedger[unIndex].unBurntTokenCount;
		}

		function doBurnPayoutForIndex(uint16 unIndex) public payable onlyOwner
		{
			require(unIndex > 0);
			require(unIndex <= m_unBurnItemCount);

			BurnPayoutTotal += msg.value;

			(bool bCurrSuccess, ) = m_mapBurnLedger[unIndex].adrOwner.call{value: msg.value}("");
			require(bCurrSuccess, "ERC721Tradable: Transfer to burn holder failed.");
		}

    function getCurrTokenId() private view returns (uint16) 
		{
        return m_unCurrTokenId;
    }

    function incrementTokenId() private 
		{
        m_unCurrTokenId++;
    }

		function lockLicense() public onlyOwner 
		{
			m_bLicenseLocked = true;
		}

		function setLicense(string memory strLicense) public onlyOwner 
		{
			require(m_bLicenseLocked == false, "ERC721Tradable: License has already been locked and cannot change.");
			m_strLicense = strLicense;
		}

		function setFreeTokenThreshold(uint16 threshold) public onlyOwner
		{
			FreeTokenThreshold = threshold;
		}

		function setShadowStartIndex(uint16 index) public onlyOwner
		{
			m_unShadowStartIndex = index;
		}

		function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Tradable: URI query for nonexistent token");

        string memory baseURI = _baseURI();
				if(tokenId >= m_unShadowStartIndex)
					return "https://ipfs.io/ipfs/QmdF5GFhniG7h9PUcy8YZKj17bCJid4j4daoc2ArSdCDGu";

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

		function setProvenance(string memory strNewProv) public onlyOwner
		{
			require(bytes(PROVENANCE).length == 0, "ERC721Tradable: Provenance is already set.");
			PROVENANCE = strNewProv;
		}
}