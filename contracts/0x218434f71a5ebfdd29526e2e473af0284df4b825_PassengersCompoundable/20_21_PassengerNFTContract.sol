//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AUpgradeable} from "./utils/ERC721AUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {UpdatableOperatorFilterer} from "./OpenseaRegistries/UpdatableOperatorFilterer.sol";
import {ICompoundable} from "./interface/ICompoundable.sol";
import {IPassengersCrate} from "./interface/IPassengersCrate.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

contract PassengersCompoundable is OwnableUpgradeable, ERC721AUpgradeable,
RevokableDefaultOperatorFiltererUpgradeable {
	
	mapping(address => bool) public isController;
	string public baseURI;
	
	modifier onlyController() {
		require(isController[msg.sender], "Not a controller");
		_;
	}
	
	function initialize() public initializer {
		__Ownable_init();
		__ERC721A_init("Passengers_Minting_Contract", "PASSENGERS");
	}
	
	function addController(address _controller) external onlyOwner {
		isController[_controller] = true;
	}
	
	function removeController(address _controller) external onlyOwner {
		isController[_controller] = false;
	}
	
	function mint(address _to, uint256 _amount) external onlyController {
		_mint(_to, _amount);
	}
	
	function burn(uint256 _tokenId) external {
		require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this token");
		_burn(_tokenId);
	}
	
	function controllerBurn(uint256 _tokenId) external onlyController {
		_burn(_tokenId);
	}
	
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
	
	function setBaseURI(string memory baseURI_) public onlyOwner {
		require(bytes(baseURI_).length > 0, "Invalid Base URI Provided");
		baseURI = baseURI_;
	}
	
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
	
	function owner()
	public
	view
	virtual
	override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
	returns (address)
	{
		return OwnableUpgradeable.owner();
	}
	
	event Attach(
		address[] indexed tailAddresses,
		uint256[] indexed tailIds,
		uint256[] indexed headIds,
		address tokenOwner
	);
	
	event Detach(
		address[] indexed tailAddresses,
		uint256[] indexed tailIds,
		uint256[] indexed headIds,
		address tokenOwner
	);
	
	address public crateContract;
	
	// this mapping keeps track of the heads of tokens getting attached to tokens of this contract
	// tailAddress => tailId => headId
	mapping(address => mapping(uint256 => uint256)) private headOf_721;
	
	// this mapping stores the array of tails belonging to a token of this contract
	// headId => tailAddress => tailIds
	mapping(uint256 => mapping(address => uint256[])) private tailsOf_721;
	
	// this mapping keeps track of the index of a tail within the tails array of a particular head
	// headId => tailAddress => tailId => index
	mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private tailIndex_721;
	
	// this mapping keeps track of the tails addresses of a particular head
	// headId => tailAddress[]
	mapping(uint256 => address[]) private tailsAddresses_721;
	
	// this mapping keeps track of the tail address index
	// headId => tailAddress => index
	mapping(uint256 => mapping(address => uint256)) private tailAddressIndex_721;
	
	// keeps track of whether a passenger token has been used to mint a crate
	// passengerId => bool
	mapping(uint256 => bool) private crateMinted;
	
	bool public isPaused;
	
	modifier whenNotPaused() {
		require(!isPaused, "Contract is paused");
		_;
	}
	
	/**
		* @notice This function allows the owner to pause the attachment and detachment of tokens.
	*/
	function togglePause() external onlyOwner {
		isPaused = !isPaused;
	}
	
	/**
		* @notice This function allows holders to attach tokens to one another. By definition, head tokens must
        * @dev belong to this contract, whereas tail tokens may or may not belong to this contract. The msg.sender must
        * @dev be the true owner of all the tokens involved in the attachment. True ownership can be verified through the
        * @dev `topOwnerOf` function.
        * @dev The tuple formed by elements from the three input arrays corresponding to a particular index
        * @dev represent one attachment triplet. Such a triplet comprises of the tokenIds of the head and the tail tokens,
        * @dev and the contract address of the tail token.
        * @param tailAddresses Array of addresses of tail contracts
        * @param tailIds Array of tail tokenIds
        * @param headIds Array of head tokenIds
    */
	function attach(
		address[] memory tailAddresses,
		uint256[] memory tailIds,
		uint256[] memory headIds
	) external whenNotPaused {
		for (uint256 i = 0; i < tailAddresses.length; i++) {
			require(ICompoundable(tailAddresses[i]).ownerOf(tailIds[i]) == msg.sender, "Attach: Not the owner of tail");
			require(topOwnerOf(headIds[i]) == msg.sender, "Attach: Not the true owner of head");
			headOf_721[tailAddresses[i]][tailIds[i]] = headIds[i];
			
			if (tailsOf_721[headIds[i]][tailAddresses[i]].length == 0) {
				tailAddressIndex_721[headIds[i]][tailAddresses[i]] = tailsAddresses_721[headIds[i]].length;
				tailsAddresses_721[headIds[i]].push(tailAddresses[i]);
			}
			tailIndex_721[headIds[i]][tailAddresses[i]][tailIds[i]] = tailsOf_721[headIds[i]][tailAddresses[i]].length;
			tailsOf_721[headIds[i]][tailAddresses[i]].push(tailIds[i]);
			
			
			if (IERC1155Upgradeable(tailAddresses[i]).supportsInterface(0xd9b67a26) == true) {
				IERC1155Upgradeable(tailAddresses[i]).safeTransferFrom(msg.sender, address(this), tailIds[i], 1, "");
			}
			else if (IERC721Upgradeable(tailAddresses[i]).supportsInterface(0x80ac58cd) == true) {
				IERC721Upgradeable(tailAddresses[i]).safeTransferFrom(msg.sender, address(this), tailIds[i]);
			}
			else {
				revert("Not supported");
			}
		}
		emit Attach(tailAddresses, tailIds, headIds, msg.sender);
	}
	
	/**
		* @notice This function allows holders to detach tokens to one another. By definition, head tokens must
        * @dev belong to this contract, whereas tail tokens may or may not belong to this contract. The msg.sender must
        * @dev be the true owner of all the tokens involved in the attachment. True ownership can be verified through the
        * @dev `topOwnerOf` function.
        * @dev The tuple formed by elements from the three input arrays corresponding to a particular index
        * @dev represent one detachment triplet. Such a triplet comprises of the tokenIds of the head and the tail tokens,
        * @dev and the contract address of the tail token.
        * @param tailAddresses Array of addresses of tail contracts
        * @param tailIds Array of tail tokenIds
        * @param headIds Array of head tokenIds
    */
	function detach(
		address[] memory tailAddresses,
		uint256[] memory tailIds,
		uint256[] memory headIds
	) external whenNotPaused {
		
		for (uint256 i = 0; i < tailAddresses.length; i++) {
				require(topOwnerOf(headIds[i]) == msg.sender, "Detach: Not the true owner of head");
				require(headOf_721[tailAddresses[i]][tailIds[i]] == headIds[i], "Detach: Tail not attached to the head");
				if (IERC1155Upgradeable(tailAddresses[i]).supportsInterface(0xd9b67a26) == true) {
					IERC1155Upgradeable(tailAddresses[i]).safeTransferFrom(address(this), msg.sender, tailIds[i], 1, "");
				}
				else if (IERC721Upgradeable(tailAddresses[i]).supportsInterface(0x80ac58cd) == true) {
					IERC721Upgradeable(tailAddresses[i]).safeTransferFrom(address(this), msg.sender, tailIds[i]);
				}
				else {
					revert("Not supported");
				}
				delete headOf_721[tailAddresses[i]][tailIds[i]];
				popTailToken(tailAddresses[i], headIds[i], tailIds[i]);
				if (tailsOf_721[headIds[i]][tailAddresses[i]].length == 0) {
					popTailAddress(headIds[i], tailAddresses[i]);
				}
		}
		emit Detach(tailAddresses, tailIds, headIds, msg.sender);
	}
	
	/**
		* @dev This function is used to detach crates for this first time.
		* @dev While doing so, it mints the tokens to the holder of the passenger tokens.
		* @param passengerIds Array of Passengers tokenIds
	*/
	function detachTSD(uint256[] memory passengerIds) external whenNotPaused {
		address[] memory crateAddresses = new address[](passengerIds.length);
		uint256[] memory crateIds = new uint256[](passengerIds.length);
		uint256 crateSupply = IPassengersCrate(crateContract).totalSupply();
		for (uint256 i = 0; i < passengerIds.length; i++) {
			require(crateMinted[passengerIds[i]] == false, "DetachTSD: Crate already minted");
			require (ownerOf(passengerIds[i]) == msg.sender, "DetachTSD: Not the owner of passenger");
			crateMinted[passengerIds[i]] = true;
			crateAddresses[i] = crateContract;
			crateSupply++;
			crateIds[i] = crateSupply;
		}
		IPassengersCrate(crateContract).mintToken(msg.sender, passengerIds.length);
		emit Detach(crateAddresses, crateIds, passengerIds, msg.sender);
	}
	
	/**
		* @notice This function sets the crate contract address
        * @param crateAddress The address of the crate contract
    */
	function setCrateAddress(address crateAddress) external onlyOwner {
		crateContract = crateAddress;
	}
	
	/**
		* @notice Given the id and the address of the tail, this function returns it's head.
        * @dev If the tail is not attached to any of the tokens, then a null address is returned.
        * @param tailAddress Contract address to which the token of interest belongs
        * @param tailId Id of the token of interest
        * @return Id of the token to which the token of interest is attached
    */
	function getHeadOf(address tailAddress, uint256 tailId) external view returns (uint256) {
		return headOf_721[tailAddress][tailId];
	}
	
	/**
		* @notice This function returns the true owner of a token, even when it's attached to another token.
        * @param tokenId Id of the token of interest
        * @return topOwner Address of the true owner
    */
	function topOwnerOf(uint256 tokenId) public view returns (address topOwner){
		address currentOwner = ownerOf(tokenId);
		if (isContract(currentOwner)) {
			try ICompoundable(currentOwner).isCompoundable() {
				uint256 headId = ICompoundable(currentOwner).getHeadOf(address(this), tokenId);
				topOwner = ICompoundable(currentOwner).topOwnerOf(headId);
			} catch {
				topOwner = currentOwner;
			}
		} else {
			topOwner = currentOwner;
		}
	}
	
	/**
		* @notice This function is used to see whether a given address is a contract
        * @param addr Address, whose contract status is to be checked
        * @return bool Returns whether the address is a contract or not
    */
	function isContract(address addr) public view returns (bool) {
		uint size;
		assembly {size := extcodesize(addr)}
		if (addr == tx.origin || size == 0)
			return false;
		else
			return true;
	}
	
	/**
		* @notice This function is used by the `topOwnerOf` function to see whether an address is a compoundable NFT contract
        * @return bool Returns true
    */
	function isCompoundable() public pure returns (bool) {
		return true;
	}
	
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `safetransfer`. This function MAY throw to revert and reject the
	///  transfer. This function MUST use 50,000 gas or less. Return of other
	///  than the magic value MUST result in the transaction being reverted.
	///  Note: the contract address is always the message sender.
	function onERC721Received(
		address,
		address,
		uint256,
		bytes memory
	) public pure virtual returns (bytes4) {
		return this.onERC721Received.selector;
	}
	
	/**
		* @notice This function is used to pop a tail token from the array of tail tokens
        * @param headId The head token id
    */
	function getTailsAddresses(uint256 headId) public view returns (address[] memory) {
		return tailsAddresses_721[headId];
	}
	
	/**
		* @notice This function returns a particular tail address of a head token
		* @notice at a particular index
		* @param headId The head token id
		* @param index The index of the tail address
	*/
	function getTailAddressByIndex(uint256 headId, uint256 index) public view returns (address) {
		return tailsAddresses_721[headId][index];
	}
	
	/**
		* @notice This function returns the length of the array of tail addresses
		* @param headId The head token id
	*/
	function totalTailAddressesOf(uint256 headId) public view returns (uint256) {
		return tailsAddresses_721[headId].length;
	}
	
	/**
		* @notice This function returns all the tails of a head belonging to a particular contract
        * @param headId TokenId of the head
        * @param tailAddress Address of the tails
        * @return Array of the ids of the tails
    */
	function getTailsPerAddressOf(uint256 headId, address tailAddress) public view returns (uint256[] memory) {
		return tailsOf_721[headId][tailAddress];
	}
	
	/**
		* @notice This function returns a particular tail of a head belonging to a particular 
		* @notice contract at a particular index
		* @param headId TokenId of the head
		* @param tailAddress Address of the tails
		* @param index Index of the tail
		* @return Id of the tail
	*/
	function getTailPerAddressByIndex(uint256 headId, address tailAddress, uint256 index) public view returns (uint256) {
		return tailsOf_721[headId][tailAddress][index];
	}
	
	/**
		* @notice This function returns the length of the tails of a head belonging to a particular contract
		* @param headId TokenId of the head
		* @param tailAddress Address of the tails
		* @return Length of the tails
	*/
	function totalTailsPerAddressOf(uint256 headId, address tailAddress) public view returns (uint256) {
		return tailsOf_721[headId][tailAddress].length;
	}
	
	/**
		* @notice This function is used to check whether a token has received airdrop or not
        * @return bool Returns whether the airdrop is received or not
    */
	function isCrateMinted(uint256 tokenId) public view returns (bool) {
		return crateMinted[tokenId];
	}
	
	/**
		* @notice This function is used to pop a tail token from the array of tail tokens
        * @param tailAddress The address of the tail contract
        * @param headId The head token id
        * @param tailId The tail token id
    */
	function popTailToken(address tailAddress, uint256 headId, uint256 tailId) internal {
		uint256 lastTokenIndex = tailsOf_721[headId][tailAddress].length - 1;
		uint256 lastToken = tailsOf_721[headId][tailAddress][lastTokenIndex];
		uint256 tokenIndex = tailIndex_721[headId][tailAddress][tailId];
		tailsOf_721[headId][tailAddress][tokenIndex] = lastToken;
		tailsOf_721[headId][tailAddress].pop();
		tailIndex_721[headId][tailAddress][lastToken] = tokenIndex;
		delete tailIndex_721[headId][tailAddress][tailId];
	}
	
	/**
		* @notice This function is used to pop a tail address from the array of tail addresses
        * @param headId The head token id
        * @param tailAddress The address of the tail contract
    */
	function popTailAddress(uint256 headId, address tailAddress) internal {
		uint256 lastAddressIndex = tailsAddresses_721[headId].length - 1;
		address lastAddress = tailsAddresses_721[headId][lastAddressIndex];
		uint256 addressIndex = tailAddressIndex_721[headId][tailAddress];
		tailsAddresses_721[headId][addressIndex] = lastAddress;
		tailsAddresses_721[headId].pop();
		tailAddressIndex_721[headId][lastAddress] = addressIndex;
		delete tailAddressIndex_721[headId][tailAddress];
	}
}