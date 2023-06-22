// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC721Metadata.sol';
import '@openzeppelin/contracts/interfaces/IERC721Enumerable.sol';
import '@openzeppelin/contracts/interfaces/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Squirrels is ERC721Enumerable, Ownable {
	/*

                                            &   . .&%# ,%(#&%(.
                                          @## (@@((/(((((((((((((%.
                                        *\/((@(#((((((((((((((((((&@&(&
                                       #&%((((((((((((((((((((((((((@#(
                                      & (%(((((((((((((((((((((((((((#((.
                                    #/@#@((((((((((((((((((((((((((((((((
                                     &###(((((((((((((((((((@&(((((((((#&
             @@((@ @@/              %  %##(((((((((((((((((@     (,&(.(
            @(((((@%&((&           #  ##[email protected]##(((((((((((((((@         (*
           @((((((@(&#((@           *#@.####((#(((((((((((((%&
       @((((((((((((&@#(@@&@        %%.%######((((((((((((((((#(#%&& ,
     @&((((((((((((((((((((((@#         (%########((((((((((((((((((.(
    @&(((((((%@((((((((((((((#((((@@((((((((((((@%####((((((((((((((@(&(
   @@(((((((@@@@&((((((((((((((((((((((((((((((((((((&####((((((((((((#(& @
   @((((((((((((((((((((((((((((((((((((((((((((((((((((#######((#((((((#&#
   @(((((((((((((((((((((((((((((((((((((((((((((((((((((%########((((((%(@.%
  (((@%(((((#######(##(((((((((((((((((((((####((((((((((((%#####(#(((((((@#@
       *@@@@@@@@%#%@###((((((((((((((###(#########(#((((((((%######(((((((###@
    %@@@@@@@@@#*%#%@##((((((((((((((########%&#######(((((((&#####((((((#####%
   (@&(((((((((((((((((((((((((((########@@##(#((((###(((((((@###(#((((((##[email protected]&
   %@(@&(##(((((((((((((((((((####%#@/#@####(((((((((#(((((((@####(((((((###@
             &#####((#############@////@####(((((((((((((((((#@###(((((####&,
                /@@@@##%#%&#@&@//////@#####(((((((((((((((((#@####(#####@@
                          ##%////////%######(((((((((((((((#&@######%###@
                          @##%///////@######((((((((((((((##@#######&@/&
                           @####@/////@######(((((((((#####@########@@
                             %####%////@######(((((((#####&%@@@@#
                               @######&(#######(#######&##
                        @###############&@@###############
                            ,#     &##############%@@@&.
    */
	// Does not contain 🥜

	using SafeMath for uint256;

	// Config Constans
	uint256 private constant price = 0.055 ether; // price of 1 squirrel
	uint256 private constant maxCountForPublicTX = 10; // max mint count per transaction in public sale
	uint256 private constant maxCountForPresaleUser = 3; // max one presale user can mint *total*
	uint256 private constant maxPresaleSupply = 1500; // max amount that presale users can mint during presale
	uint256 private constant maxSupply = 5555; // total max amount of squirrels

	// Current Maximum amount of Squirrels
	uint256 public maxMintingSupply = 555;

	// togglables
	bool public presaleActive = false;
	bool public publicSaleActive = false;
	bool public metadataLocked = false; // is the metadata frozen/locked

	// Addresses
	address public constant signer = 0x800f9038bBED306e394ee93d5893D6B6cAbee312;
	address private constant addr1 = 0xccc72E62A702cE7bAbb75dd1120521d57101a516;
	address private constant addr2 = 0xfE57f843A54903b6959FcB6009ba09003c46e703;
	address private constant addr3 = 0xAEF0741b4D0cFd43696dEb237A76141959Fd0824;
	address private constant addr4 = 0x5A3bF7007834E9DC7905bb107dD57412d9f91B47;

	// Metadata
	string private baseURI; // base uri of metadata

	// Keeping things fair!
	mapping(address => uint256) public presaleMintedPerUser; // stores the amount that presale users have minted, e.g. if tom mints 2 squirrels, presaleMintedPerUser[tom] will be 2
	uint256 public presaleMintedTotal = 0; // total amount that all presale users have minted during presale
	uint256 public ownerMintedTotal = 0; // total amount that owner wallet has minted using mintForOwner()

	constructor() public ERC721('Sneaky Squirrels', 'SQL') {} // setup contract, first value is the name, second is the symbol or shorthand

	modifier onlyValidAccess(
		bytes32 hashBytes,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) {
		require(hashBytes == calculateSenderHash(), 'Invalid hash');
		bytes memory prefix = '\x19Ethereum Signed Message:\n32';
		bytes32 prefixedProof = keccak256(abi.encodePacked(prefix, hashBytes));
		address recovered = ecrecover(prefixedProof, _v, _r, _s);
		require(recovered == signer, 'Not signed by signer');
		_;
	}

	function calculateSenderHash() internal view returns (bytes32 hash) {
		bytes memory packed = abi.encodePacked(msg.sender);
		bytes32 hashResult = keccak256(packed);
		return hashResult;
	}

	function mintForSale(uint256 amount) public payable {
		require(publicSaleActive, 'Sale is not active');
		require(amount <= maxCountForPublicTX, 'Max tokens is 10');
		require(totalSupply().add(amount) <= maxMintingSupply, 'TX would mint over the total');
		require(price.mul(amount) == msg.value, 'Over or underpaid');

		// loop <amount> times, if the total supply is under the max, mint with id INDEX+1
		for (uint256 i = 0; i < amount; i++) {
			uint256 mintIndex = totalSupply().add(1);
			if (totalSupply() < maxMintingSupply) {
				_safeMint(msg.sender, mintIndex);
			}
		}
	}

	function presaleMint(
		uint256 amount,
		bytes32 hashBytes,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public payable onlyValidAccess(hashBytes, _v, _r, _s) {
		require(presaleActive, 'Presale has not been started or is over');
		require(amount <= maxCountForPresaleUser, 'Amount is too high');
		require(
			presaleMintedPerUser[msg.sender].add(amount) <= maxCountForPresaleUser,
			'Amount is too high (with the amount you have already minted)'
		);
		require(
			presaleMintedTotal.add(amount) <= maxPresaleSupply,
			'Amount is too high (Would go over the presale reserve)'
		);
		require(totalSupply().add(amount) <= maxMintingSupply, 'TX would mint over the total');
		require(price.mul(amount) == msg.value, 'Over or underpaid');
		// loop <amount> times, if the total supply is under the max, mint with id INDEX+1
		for (uint256 i = 0; i < amount; i++) {
			uint256 mintIndex = totalSupply().add(1);
			if (totalSupply() < maxMintingSupply) {
				_safeMint(msg.sender, mintIndex);
			}
		}
		presaleMintedPerUser[msg.sender] = presaleMintedPerUser[msg.sender].add(amount);
		presaleMintedTotal = presaleMintedTotal.add(amount);
	}

	// Mint 100 tokens for use in giveaways, team mints, etc. Will not work once 100 squirrels have been minted | This can only be ran by the address that deployed the contract.
	function mintForOwner(uint256 amount) public onlyOwner {
		require(ownerMintedTotal.add(amount) <= 100, 'Would mint too many');
		require(totalSupply().add(amount) <= maxMintingSupply, 'TX would mint over the total');
		// loop <amount> times, if the total supply is under the max, mint with id INDEX+1
		for (uint256 i = 0; i < amount; i++) {
			uint256 mintIndex = totalSupply().add(1);
			if (totalSupply() < maxMintingSupply) {
				_safeMint(msg.sender, mintIndex);
			}
		}
		ownerMintedTotal = ownerMintedTotal.add(amount);
	}

	// turn the public sale on or off | This can only be ran by the address that deployed the contract.
	function togglePublicSale() public onlyOwner {
		// true -> false, false -> true
		publicSaleActive = !publicSaleActive;
	}

	// turn the presale on or off | This can only be ran by the address that deployed the contract.
	function togglePresale() public onlyOwner {
		// true -> false, false -> true
		presaleActive = !presaleActive;
	}

	// withdraw smart contract balance | This can only be ran by the address that deployed the contract.
	function withdraw() public onlyOwner {
		// smart contract balance
		uint256 balance = address(this).balance;

		// 43.75%
		require(payable(addr1).send(balance.mul(4375).div(10000)), 'addr1 failed');
		// 43.75%
		require(payable(addr2).send(balance.mul(4375).div(10000)), 'addr2 failed');
		// 10%
		require(payable(addr3).send(balance.mul(10).div(100)), 'addr3 failed');
		// 2.5%
		require(payable(addr4).send(balance.mul(25).div(1000)), 'addr4 failed');
	}

	// This is ONLY IF the above function does not work, and will not be used lightly
	function emergencyWithdraw() public onlyOwner {
		// smart contract balance
		uint256 balance = address(this).balance;

		require(payable(msg.sender).send(balance), 'withdraw failed');
	}

	function bumpMintingSupply() public onlyOwner {
		require(maxMintingSupply < maxSupply, 'Minting supply already maxed');
		maxMintingSupply = maxMintingSupply.add(1000);
	}

	// This gives the url of where the metadata is stored
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	// Sets the above value, if the contract is locked we say no! | This can only be ran by the address that deployed the contract.
	function setBaseURI(string memory uri) external onlyOwner {
		require(!metadataLocked, 'Metadata is locked.');
		baseURI = uri;
	}

	// Lock metadata, no rugging allowed! | This can only be ran by the address that deployed the contract.
	function lockMetadata() public onlyOwner {
		metadataLocked = true;
	}
}