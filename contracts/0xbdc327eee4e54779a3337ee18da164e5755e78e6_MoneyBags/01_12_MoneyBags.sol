// SPDX-License-Identifier: Proprietary
// Creator: António Nunes Duarte;

pragma solidity ^0.8.0;

// Imports
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
	@dev Implementation of MoneyBags Token, using the [ERC721A] standard for optimized
	gas costs, specially when batch minting Tokens.

	This token works exclusively in a Whitelist so there is no need to close and open whitelist.
 */
contract MoneyBags is ERC721A, Ownable {
	constructor(address _adminSigner) ERC721A("MoneyBags", "MBG") {
		adminSigner = _adminSigner;
	}

	// Chainlink related configs.
	address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
	address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
	bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
	uint32 callbackGasLimit = 100000;
	uint16 requestConfirmations = 3;
	uint32 numWords =  1;
	uint256[] public s_randomWords; // Where the random values are stored 
	uint256 public s_requestId;
	address s_owner;
		
	// Minting related variables
	uint private mintPrice = 100000000;
	uint16 private numberOfTokens = 5555;
	uint private numberPrizes = 0;
	mapping(uint => bool) alreadySelected;

	string private baseURI; 

	/**
	 *  
	 *	0 -> [Closed]
	 *	1 -> [Whitelist]
	 *		Ballers -> Mint (2)
	 *		Stacked -> Mint (1)
	 *	
	 * 	2 -> [Community FFA]
	 *		Ballers -> Mint (2)
	 * 		Stacked -> Mint (1)
	 *		Community -> Mint (1)
	 *		
	 *	3 -> [Public]
	 *		Everyone -> Mint (3)
	*/
	uint16 private mintingPhase = 0;

	bool private withdrawSelected = false;
	bool private isWinnerSelected = false;

	// The time at which the collection 
	uint256 private withdrawTime = 0;

	// Coupon for signature verification
	struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	enum CouponType {
		Ballers,
		Stacked,
		Community
	}

	struct Winner {
		uint winner; // winner NFT index in the ERC721A array  
		bool prizeClaimed; // was the prize already claimed?
	}

	// The list of participations
	Winner[] public winners;

	uint16 constant NUMBER_PRIZES = 556;

	uint constant NUMBER_FIRST_PRIZE = 1;
	uint constant NUMBER_SECOND_PRIZE = 5;
	uint constant NUMBER_THIRD_PRIZE = 50;
	uint constant NUMBER_FOURTH_PRIZE = 500;

	uint firstPrize; // [ASSIGN] [DONE]
	uint secondPrize; // [ASSIGN] [DONE]
	uint thirdPrize; // [ASSIGN] [DONE]
	uint fourthPrize; // [ASSIGN] [DONE]

	// The signer address (Whitelist)
	address private adminSigner;

	/* ---------------- */
	/* Public Functions */
	/* ---------------- */

	function setAdminSigner(address _signer) public onlyOwner {
		adminSigner = _signer;
	}

	/**
		@dev Function that allows minting of an NFT.
	 */
	function mint(
		address _to,
		uint _quantity,
		Coupon calldata _coupon
	) public payable {
		uint quantityCanMint = 0;

		if (!(mintingPhase == 3)) {
			require(mintingPhase > 0, "Error: Minting Closed");

			CouponType personalCoupon;
			bool couponVerified = false;
	
			bytes32 digestBallers = keccak256(abi.encode(CouponType.Ballers, _to));
			bytes32 digestStacked = keccak256(abi.encode(CouponType.Stacked, _to));
			bytes32 digestCommunity = keccak256(abi.encode(CouponType.Community, _to));

			if (_isVerifiedCoupon(digestBallers, _coupon)) {
				personalCoupon = CouponType.Ballers;
				quantityCanMint = 2;
				couponVerified = true;
			}
			else if (_isVerifiedCoupon(digestStacked, _coupon)) {
				personalCoupon = CouponType.Stacked;
				quantityCanMint = 1;
				couponVerified = true;
			}
			else if (_isVerifiedCoupon(digestCommunity, _coupon)) {
				personalCoupon = CouponType.Community;
				quantityCanMint = 3;
				couponVerified = true;
			}

			require(couponVerified, "Error: You have no key, wait for the public mint"); 

			if (mintingPhase == 1) {
				require(personalCoupon == CouponType.Ballers || personalCoupon == CouponType.Stacked, "Error: Invalid token");
			} 
			else if (mintingPhase == 2) {
				require(personalCoupon == CouponType.Ballers || personalCoupon == CouponType.Stacked || personalCoupon == CouponType.Community, "Error: Invalid token");
			}
		
		} else require (mintingPhase == 3, "Error: Invalid token");

		if (mintingPhase == 3) quantityCanMint = 3;
		
		require(_quantity > 0, "Error: You need to Mint more than one Token.");
		require((_quantity + totalSupply()) < 5555, "Error: The quantity you're trying to mint excceeds the total supply");
		require(_quantity + _addressData[_to].numberMinted <= quantityCanMint, "Error: You can't mint that quantity of tokens.");
		require(msg.value >= ((_quantity * mintPrice) * (1 gwei)), "Error: You aren't paying enough.");

		_mint(_to, _quantity, "", false);
	}

	function selectWinnerWithdraw() public payable {
		require(!isWinnerSelected); // If winner is selected can't re-run it
		
		// The owners have a 24h grace period to call it themselves
		if ((block.timestamp - withdrawTime) < 1 days) {
			require(msg.sender == owner());
		} 

		uint random = super.chainlinkFullFillRandom();

		if (NUMBER_PRIZES < super.totalSupply()) {
			numberPrizes = NUMBER_PRIZES;
		}
		else {
			numberPrizes = super.totalSupply();
		}

		// Expand one random value into x random values by encoding and hashing
		for (uint i = 0; i < numberPrizes; i++) {
			uint256 winnerIndex = uint256(keccak256(abi.encode(random, i))) % super.totalSupply();

			while (alreadySelected[winnerIndex]) {
				winnerIndex++;
			}

			Winner memory winner = Winner(winnerIndex, false);
			alreadySelected[winnerIndex] = true;
			winners.push(winner);
		}

		// Prize value selection logic:
		firstPrize = (address(this).balance *  90009000900090000 / 1000000000000000000);
		secondPrize = (address(this).balance * 18001800180018002 / 1000000000000000000);
		thirdPrize = (address(this).balance *  18001800180018002 / 10000000000000000000);
		fourthPrize = (address(this).balance * 18001800180018002 / 100000000000000000000);

		// Comission distribution:
		distributeComissions();

		isWinnerSelected = true;
	}

	/**
	* @dev Distribute the comissions to the members of the team.
	*/
	function distributeComissions() public onlyOwner {
		uint balance = address(this).balance;

		uint firstValue = balance * 1530153015 / 10000000000;
		uint secondValue = balance * 7200720072007201 / 100000000000000000;
		uint thirdValue = balance * 36003600360036003 / 10000000000000000000;
									  
		uint fourthValue = balance * 35 / 1000;
		uint fifthValue = balance * 45 / 1000;
		uint devValue = balance * 25 / 1000;
		
		uint sixthValue = balance * 18001800180018002 / 10000000000000000000;

		payable(0xAE503cB1F8c5F1b999623b66A31c84122e123Ae7).call{ value: firstValue }("");

		payable(0x0359C701895Db8FCBc5e6CaE023d508fa309EeD4).call{ value: firstValue }("");
		payable(0x55C8D0ef52494690E829e8246dDdaE58b5CA0186).call{ value: secondValue }("");
		payable(0xd7f87f147c895454c256d242A8379869a98aac6a).call{ value: thirdValue }("");

		payable(0x29D44168b2C576930086FF412B94A9cB2A07cA50).call{ value: fourthValue }("");
		payable(0xeD6875a961D38076ADb27226aa0865b09225dc7e).call{ value: fifthValue }("");
		payable(0xc8fab3b8753984b7D8f413b730A211b0eDde3B7c).call{ value: devValue }("");

		payable(0x46d11DC635e3d772Beda70E3fa49a5242ad763b1).call{ value: sixthValue }("");
		payable(0xcE34f4A7A2E7E76440110220856e8C822886B205).call{ value: sixthValue }("");
		payable(0x1bE2e5c277f77679888B11c9311680fe873d3a3b).call{ value: sixthValue }("");
		payable(0xe84Dd44483Fe46AB108748D20FDE5040c5AA857C).call{ value: sixthValue }("");
		payable(0xCa1d749457109cfc162DD4FDaB7E1956DFeBDfB0).call{ value: sixthValue }("");
		payable(0xc7F90cf9033bA51C166002A960bc276274bB7769).call{ value: sixthValue }("");
		payable(0xd87697D737DD4E51347677fBCCA92a2BB4C4c756).call{ value: sixthValue }("");
	}

	function getWinners() public view returns(Winner[] memory)  {
		return winners;
	}

	/**
	* @dev Function that allows the owner of the contract to withdraw the funds
	* x days after the winner is selected.
	*/
	function withdrawFunds() payable public onlyOwner {
		require(block.timestamp > withdrawTime + 7 days);
		(bool success, ) = payable(owner()).call{ value: address(this).balance }("");
		require(success);
	}


	// [MOST IMPORTANT FUNCTION]
	function claimPrize() payable external {
		require(isWinnerSelected); // Require that the winner is already selected.

		uint totalPrize = 0;		
		for (uint i = 0; i < numberPrizes; i++) {
			if (msg.sender == ownerOf(winners[i].winner)) {
				if (!winners[i].prizeClaimed) {
					if (i == 0) {
						totalPrize += firstPrize;
					}
					else if (i == 1 || i == 2 || i == 3 || i == 4 || i == 5) {
						totalPrize += secondPrize;
					}
					else if (i >= 6 && i <= 56) {
						totalPrize += thirdPrize;
					}
					else {
						totalPrize += fourthPrize;
					}
					
					winners[i].prizeClaimed = true;
				}
			}
		}

		// transfer prize
		if (totalPrize > 0) {
			(bool success, ) = payable(msg.sender).call{ value: totalPrize }("");
			require(success);
		}
	}

	/**
	* @dev Selects minting phase
	*/
	function selectMintingPhase(uint16 phase) external onlyOwner {
		mintingPhase = phase;
	}

	/**
		@dev Sets the withdraw time and starts the lottery.
	*/
	function setWithdrawTime(uint _date) external onlyOwner {
		require(!withdrawSelected);

		withdrawSelected = true;
		withdrawTime = _date;
	}

	function setBaseURI(string memory _uri) public onlyOwner {
		baseURI = _uri;
	}

	/* ------------------- */
	/* Auxiliary Functions */
	/* ------------------- */

	/**
		@dev Function to indicate the base URI of the metadata.
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI; // TODO: Replace with true metadata
	}

	/**
	 	@dev check that the coupon sent was signed by the admin signer
	*/
	function _isVerifiedCoupon(bytes32 _digest, Coupon memory _coupon)
		internal
		view
		returns (bool)
	{
		address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
		require(signer != address(0), 'ECDSA: Invalid signature'); // Added check for zero address
		return signer == adminSigner;
	}

	/* --------- */
	/* Modifiers */
	/* --------- */

	/**
		@dev Modifier to ensure that the owner can only trigger the function before the lottery starts.
	*/
	modifier ownerCanTrigger() {
		require(withdrawTime < block.timestamp, "Lottery: You can't trigger the function before the lottery ends.");
		_;
	}

}