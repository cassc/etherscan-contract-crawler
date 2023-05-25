// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../facets/ArtworkFacet.sol";
import "../libraries/ERC721A.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/Constants.sol";
import "../libraries/IOpenseaSeaportConduitController.sol";
import "hardhat/console.sol";

contract TokenFacet is
	ERC721A,
	EIP712,
	Context
{
	IOpenseaSeaportConduitController public constant OPENSEA_SEAPORT_CONDUIT_CONTROLLER = IOpenseaSeaportConduitController(0x00000000F9490004C11Cef243f5400493c00Ad63);
    address public constant OPENSEA_SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;


	constructor()
		ERC721A(Constants.NAME, Constants.SYMBOL)
		EIP712(Constants.NAME, Constants.VERSION)
	{}
	
	// =================================
	// Minting
	// =================================

	function mint(uint256 tokenCount, bytes calldata signature)
		external
		whenNotPaused
	{
		// WL
		if (signature.length > 0) {
			require(getState().wlMinting, "E05");
			require(SignatureChecker.isValidSignatureNow(
				// TODO: change to separate wallet
				LibDiamond.contractOwner(),
				_hashTypedDataV4(
					keccak256(abi.encode(
						keccak256("SAUD(address a,uint256 c)"),
						_msgSender(),
						tokenCount
					))
				),
				signature
			), "E04");
			require(_numberMinted(_msgSender()) < tokenCount, "E02");
		// non-WL
		} else {
			require(!getState().wlMinting, "E06");
			require(_msgSender().balance >= Constants.MIN_ETH_BALANCE, "E01");
			require(_numberMinted(_msgSender()) + tokenCount <= Constants.MAX_MINT_PER_WALLET, "E02");
		}

		require(totalSupply() + tokenCount <= Constants.MAX_SUPPLY, "E03");
		_safeMint(_msgSender(), tokenCount);
	}

	// TODO: Add to Init
    // function safeMint(address to, uint256 tokenCount)
    //     public
	// 	onlyOwner
    // {
    //     _safeMint(to, tokenCount);
    // }

	// =================================
	// Metadata
	// =================================

	function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
		require(_exists(tokenId), 'E10');
		return string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(
					abi.encodePacked(
						'{',
							'"name": "', getState().name, ' #', Strings.toString(tokenId), '", ', // The Saudis #1234
							'"description": ', getState().description, ' ,',
							'"image_data": "data:image/svg+xml;base64,', ArtworkFacet(address(this)).generateSvg(tokenId), '", ',
							'"external_url": "', getState().tokenBaseExternalUrl, Strings.toString(tokenId), '", ',
						'}' 
					)
				)
			)
		);
    }

	function contractURI()
		public
		view
		returns (string memory)
	{
        return string(
			abi.encodePacked(
				'data:application/json;base64,',
				Base64.encode(
					abi.encodePacked(
						'{',
							'"name": ', getState().name, ', ',
							'"description": ', getState().description, ' ,',
							'"image": "', getState().contractLevelImageUrl, '", ',
							'"external_url": "', getState().contractLevelExternalUrl, '", ',
							'"seller_fee_basis_points": ', getState().royaltyBasisPoints, ', ',
							'"fee_recipient": "', getState().royaltyWalletAddress, '"', 
						'}' 
					)
				)
			)
		);
    }

	/**
     * Override isApprovedForAll to whitelist Seaport's conduit contract to enable gas-less listings.
     */
    function isNFTApprovedForAll(address owner, address operator) external view returns (bool) {
        try OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(operator, OPENSEA_SEAPORT) returns (bool isOpen) {
            if (isOpen) {
                return true;
            }
        } catch {}

        return super.isApprovedForAll(owner, operator);
    }

	// =================================
	// Config
	// =================================

	function setWlMinting(bool state)
		public onlyOwner
	{
		getState().wlMinting = state;
	}

	function setTokenBaseExternalUrl(string memory url)
		public onlyOwner
	{
        getState().tokenBaseExternalUrl = url;
    }

	function setContractLevelImageUrl(string memory url)
		public onlyOwner
	{
		getState().contractLevelImageUrl = url;
	}

	function setContractLevelExternalUrl(string memory url)
		public onlyOwner
	{
		getState().contractLevelExternalUrl = url;
	}
}