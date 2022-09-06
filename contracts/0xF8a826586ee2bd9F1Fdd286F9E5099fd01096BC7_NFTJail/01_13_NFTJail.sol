/*
   . *@O°                . [email protected]°                  [email protected]                 .#@o.                 °@@o.               . *@#o.
   . *@O°                . [email protected]°                . [email protected]° .             . .#@o. .             . °@@o. .             . *@#o.
     *@o.                  [email protected]                  [email protected]                 .##o.                 [email protected]#o                  *@#*
****°o#Oo*****************°o#o**°°°**°°°°°°°°°°°°OOo**°°°°°°°°°°°°°°°°*OOo*°°°°°°°°°°°°°°°°°*OOo*°°°°°°°°°°°°°°°°°oOOo*°
[email protected]@@#[email protected]@@#.................#@@@O................°@@@@o................°@@@@*[email protected]@@@°
     *@##O                 [email protected]##O                 [email protected]##o                [email protected]@##*                °@@##°                *@@##.
   . *@O°..              . [email protected]°.                 #@O°.                [email protected]@o°.                °@@o°.              . *@#o°
   . *@O°                . [email protected]°                  #@O°               . [email protected]@o°                 °@@o. . .  .        . *@#o.
   . *@O°        . .       [email protected]°                  [email protected]°                 [email protected]@O°               . °@@o°         . .   . *@#o.
   . *@O°    ...     ...°[email protected]° .        .     ..#@O.°*°°**°°**..°°°°°°@@o°                 °@@o°..°o.°*..    . . *@#o.
   . *@O°  .    °*°oO°*°.*@[email protected]°.**°°°.     ..°ooo#@O°°*o*********[email protected]@O.**°°..      ..°***@@o.*o#O °.OOo°*°  . *@#o.
   . *@O°   °**o#o*Oo*.  O#[email protected]°.oOO**o**°*o*o****#@O°°oooo********oo***@@O.°o*ooo*°.°°***[email protected]@o°*@o o. @°o*@@O°  *@#o.
   . *@O° .##[email protected]@°°*ooo# [email protected]*[email protected]°.**#o***oO#O**ooo*#@O°.°°°**ooo*********@@O°°*****o#O*[email protected]@o°°*@.° *@°*°#O#@* *@#o.
   . *@O° [email protected]#[email protected]#o°°**O#@°@[email protected]°.oo***[email protected]****oO*°. #@O°°*°.  ..o#********@@[email protected]****oO#o*o*****@@o.*@O °OO*[email protected]@°*@#o.
   . *@O°   [email protected]#o°*o°oO*°.. [email protected]° .°*°*#O****@°    #@O°°**. .. °@*******[email protected]@O.*@Ooo***o#o*******@@o.°O.OOO*OO°#°* *@ *@#o.
   . *@O°   [email protected]***[email protected]      [email protected]°     °@*****#Oo***#@O°.°°****o#OooOO***[email protected]@[email protected]*o*O* ..... °@@o°   OoOoO*°o°°°*@ *@#o.
   . *@O° .o#o°°*°**@ .  . [email protected]°   ...#O*****ooooo#@O°°OOOOoooo#@##@@o*[email protected]@O°*oo****OO°     . °@@o° .  .*#[email protected]**oo*# *@#o°
   . *@O° o#°°°°oo°o#o .   [email protected]°  ... o#oo******o*#@O°.********[email protected]##@@o**@@O°°***OOooO°       °@@o°   . [email protected]*.o*o.°@ *@#o°
   . *@O°  O#o*°*oo##  . °*[email protected]°       .°*oo******#@O°.*********oooo****#@o°°ooooO*°..°°°°°°.°@@o°    .OO*°o.*.oOO *@#o.
     *@O°   @*o**°°*Oo°  .°[email protected]°°#Oo°......°ooooOO#@O°°[email protected]@O°°OooOOo#@#Oo**°° °@@o° . °@o°°O ***O*  *@#o.
.....*#o.   o°.°°°°°°*O*.°ooOo. o#OOoooooOOooooo*OO* .Oo°*O**oo**oOOoooOO* °o**oooO°°°   ...°OO*    *°  ....oO. ..*OO*
°°°°°*OOOo.°..°******°°°°°°oOOO*....ooOOoooooOo*ooOOooOO°*°°°*°°o#o°*ooOOoo*°oOooo*oo.°°°°°°°OOoo°.....°°°°°...°°.*Oooo°
     [email protected]@@#     ......      [email protected]@@O .°[email protected]@##@@ooO###[email protected]@@@@#[email protected]°°**°o*#@O .°@@@@Ooo##o**O#.      °@@@@° ... ....       *@@@@°
   . *@#OO               . [email protected]#OO**oo    [email protected]°##°.  #@#OOo#@****°**[email protected]@# .#@#O#.               °@@#O°              . *@@#O.
   . *@O°.               . [email protected]°..    °oooo°°.    #@O°**@@OOOooOO#@@[email protected]@@o°.  .  ...        °@@o°               . *@@o°

NFT Jail
An experimental project by Neon Nacho Labs
https://neonnacho.xyz

Find a bug? Let me know.
https://github.com/Neon-Nacho-Labs
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTJail is ERC721, ERC721URIStorage, Ownable {
	using Counters for Counters.Counter;

	// Starts counting at 1 instead of 0
	Counters.Counter public tokenIdCounter;

	// Track minted tokens by parent address and id
	mapping (bytes32 => bool) public parentTokenTracker;

	constructor() ERC721("NFTJail", "NFTJAIL") {}

	function _baseURI() internal pure override returns(string memory) {
		return "ipfs://";
	}

	/**
	 * Go to jail!
	 * Mints an NFT based an existing one from a different contract.
	 */
	function mint(address parentContractAddress, uint256 parentTokenId, string calldata _tokenURI) external payable {
		bytes32 parentHash = keccak256(abi.encode(parentContractAddress, parentTokenId));
		// Each parent address/token can only be minted once
		require(!parentTokenTracker[parentHash], "Parent token already exists");

		// Caller must own the parent token
		require(msg.sender == IERC721(parentContractAddress).ownerOf(parentTokenId), "Caller does not own the parent token");

		// Keep track of parent tokens to prevent duplicates
		parentTokenTracker[parentHash] = true;

		tokenIdCounter.increment();
		_safeMint(msg.sender, tokenIdCounter.current());
		_setTokenURI(tokenIdCounter.current(), _tokenURI);
	}

	/**
	 * Allow funds to be withdrawn by the owner
	 */
	function withdrawAll() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success, "Withdrawal failed");
    }

	/**
	 * Receive function in case eth gets sent to the contract
	 */
	receive() external payable {}

	// Override functions
	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}