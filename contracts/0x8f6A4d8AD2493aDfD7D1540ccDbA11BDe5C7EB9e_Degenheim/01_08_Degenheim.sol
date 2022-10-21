// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

Degenheim.sol

Written by: mousedev.eth

*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MerkleWhitelist.sol";

interface IDegenesis {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IDegenheimRenderer {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract Degenheim is ERC721A, Ownable, MerkleWhitelist {
    string public contractURI = "ipfs://QmQi2F99Dkg4comZzFvcXMrXrVqDeMoBLXp5vgZmo9VWbJ";

    uint256 public maxSupply = 7777;
    uint256 public maxSupplyInPublicSale = 6450;
    uint256 public numMintedInPublicSale = 0;
    uint256 public price = 0.08 ether;

    address public degenesisAddress;
    address public degenheimRendererAddress;

    struct SaleTierDetails {
        //Timing
        uint64 startTimestamp;
        uint64 endTimestamp;
        //Paused override.
        bool paused;
        //How many can be minted for a user.
        uint16 mintLimit;
    }

    mapping(uint8 => SaleTierDetails) public saleTierDetails;

    constructor() ERC721A("Degenheim", "DGNH") {
        //OG sale
        saleTierDetails[0] = SaleTierDetails({
            startTimestamp: 1666282500,
            endTimestamp: 10000000000000,
            paused: false,
            mintLimit: 2
        });

        //WL sale
        saleTierDetails[1] = SaleTierDetails({
            startTimestamp: 1666282500,
            endTimestamp: 10000000000000,
            paused: false,
            mintLimit: 1
        });

        //Collablist
        saleTierDetails[2] = SaleTierDetails({
            startTimestamp: 1666284300,
            endTimestamp: 10000000000000,
            paused: false,
            mintLimit: 1
        });

        //Public Sale
        saleTierDetails[3] = SaleTierDetails({
            startTimestamp: 1666289700,
            endTimestamp: 10000000000000,
            paused: false,
            mintLimit: 3
        });
    }

    /*
  _____ _   _ _______ ______ _____  _   _          _        ______ _    _ _   _  _____ _______ _____ ____  _   _  _____ 
 |_   _| \ | |__   __|  ____|  __ \| \ | |   /\   | |      |  ____| |  | | \ | |/ ____|__   __|_   _/ __ \| \ | |/ ____|
   | | |  \| |  | |  | |__  | |__) |  \| |  /  \  | |      | |__  | |  | |  \| | |       | |    | || |  | |  \| | (___  
   | | | . ` |  | |  |  __| |  _  /| . ` | / /\ \ | |      |  __| | |  | | . ` | |       | |    | || |  | | . ` |\___ \ 
  _| |_| |\  |  | |  | |____| | \ \| |\  |/ ____ \| |____  | |    | |__| | |\  | |____   | |   _| || |__| | |\  |____) |
 |_____|_| \_|  |_|  |______|_|  \_\_| \_/_/    \_\______| |_|     \____/|_| \_|\_____|  |_|  |_____\____/|_| \_|_____/ 
 */

    function _getAuxIndex(uint8 _index) internal view returns (uint8) {
        return uint8(_getAux(msg.sender) >> (_index * 8));
    }

    function _setAuxIndex(uint8 _index, uint8 _num) internal {
        //Thx to @nftdoyler for helping me with bit shifting.
        uint256 bitMask = (2**(8 * (_index + 1)) - (2**(8 * _index)));
        _setAux(
            msg.sender,
            uint64(
                (_getAux(msg.sender) & ~bitMask) |
                    ((_num * (2**(8 * _index))) & bitMask)
            )
        );
    }

    /*
 _  _  __  __ _  ____    ____  _  _  __ _   ___  ____  __  __   __ _  ____ 
( \/ )(  )(  ( \(_  _)  (  __)/ )( \(  ( \ / __)(_  _)(  )/  \ (  ( \/ ___)
/ \/ \ )( /    /  )(     ) _) ) \/ (/    /( (__   )(   )((  O )/    /\___ \
\_)(_/(__)\_)__) (__)   (__)  \____/\_)__) \___) (__) (__)\__/ \_)__)(____/
*/

    function mintPublic(uint8 _quantity) public payable {
        require(
            numMintedInPublicSale + _quantity <= maxSupplyInPublicSale,
            "Max supply for public sale reached!"
        );

        require(
            (block.timestamp >= saleTierDetails[3].startTimestamp &&
                block.timestamp < saleTierDetails[3].endTimestamp) &&
                !saleTierDetails[3].paused,
            "This sale tier is not active!"
        );

        uint8 mintedAmount = _getAuxIndex(3);

        //Require they haven't minted their allocation.
        require(
            mintedAmount + _quantity <= saleTierDetails[3].mintLimit,
            "You've minted your allocation!"
        );

        require(msg.value >= _quantity * price, "Must send enough ether!");

        //Store they minted this many.
        _setAuxIndex(3, mintedAmount + _quantity);

        //Add this many minted to storage of minting.
        numMintedInPublicSale += _quantity;

        //Mint them their tokens.
        _mint(msg.sender, _quantity);

        return;
    }

    function mint(
        bytes32[] calldata proof,
        uint8 _saleTier,
        uint8 _quantity
    ) public payable onlyWhitelisted(proof, _saleTier) {
        //Ensure total supply doesnt exceed max supply
        require(
            numMintedInPublicSale + _quantity <= maxSupplyInPublicSale,
            "Max supply for public sale reached!"
        );

        require(
            (block.timestamp >= saleTierDetails[_saleTier].startTimestamp &&
                block.timestamp < saleTierDetails[_saleTier].endTimestamp) &&
                !saleTierDetails[_saleTier].paused,
            "This sale tier is not active!"
        );

        uint8 mintedAmount = _getAuxIndex(_saleTier);

        //Require they haven't minted their allocation.
        require(
            mintedAmount + _quantity <= saleTierDetails[_saleTier].mintLimit,
            "You've minted your allocation!"
        );

        require(_quantity > 0, "Quantity must be greater than 0.");

        require(msg.value >= _quantity * price, "Must send enough ether!");

        //Store they minted this many.
        _setAuxIndex(_saleTier, mintedAmount + _quantity);

        //Add this many minted to storage of minting.
        numMintedInPublicSale += _quantity;

        //Mint them their tokens.
        _mint(msg.sender, _quantity);

        return;
    }

    /*
   U  ___ u              _   _   U _____ u   ____          _____    _   _   _   _      ____   _____             U  ___ u  _   _    ____     
    \/"_ \/__        __ | \ |"|  \| ___"|/U |  _"\ u      |" ___|U |"|u| | | \ |"|  U /"___| |_ " _|     ___     \/"_ \/ | \ |"|  / __"| u  
    | | | |\"\      /"/<|  \| |>  |  _|"   \| |_) |/     U| |_  u \| |\| |<|  \| |> \| | u     | |      |_"_|    | | | |<|  \| |><\___ \/   
.-,_| |_| |/\ \ /\ / /\U| |\  |u  | |___    |  _ <       \|  _|/   | |_| |U| |\  |u  | |/__   /| |\      | | .-,_| |_| |U| |\  |u u___) |   
 \_)-\___/U  \ V  V /  U|_| \_|   |_____|   |_| \_\       |_|     <<\___/  |_| \_|    \____| u |_|U    U/| |\u\_)-\___/  |_| \_|  |____/>>  
      \\  .-,_\ /\ /_,-.||   \\,-.<<   >>   //   \\_      )(\\,- (__) )(   ||   \\,-._// \\  _// \\_.-,_|___|_,-.  \\    ||   \\,-.)(  (__) 
     (__)  \_)-'  '-(_/ (_")  (_/(__) (__) (__)  (__)    (__)(_/     (__)  (_")  (_/(__)(__)(__) (__)\_)-' '-(_/  (__)   (_")  (_/(__)      
*/

    function airdropToDegenesisOwners(
        uint256 _startingPassId,
        uint256 _endingPassId,
        uint256 _quantityToAirdrop
    ) public onlyOwner {
        uint256 quantityMinting = (_endingPassId - _startingPassId) *
            _quantityToAirdrop;

        require(
            totalSupply() + quantityMinting <= maxSupply,
            "Exceeds max supply!"
        );
        require(_startingPassId >= 0 && _endingPassId <= 299, "Invalid IDs");

        for (uint256 i = _startingPassId; i <= _endingPassId; i++) {
            address thisOwner = IDegenesis(degenesisAddress).ownerOf(i);
            _mint(thisOwner, _quantityToAirdrop);
        }
    }

    function airdrop(address[] memory _addresses) public onlyOwner {
        require(
            totalSupply() + _addresses.length <= maxSupply,
            "Exceeds max supply!"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function mintTeam(uint256 _quantity, address _receiver) public onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Max supply reached!");
        _mint(_receiver, _quantity);
    }

    function adjustSaleTierDetails(
        uint8 _index,
        SaleTierDetails calldata _saleTierDetails
    ) public onlyOwner {
        saleTierDetails[_index] = SaleTierDetails(
            _saleTierDetails.startTimestamp,
            _saleTierDetails.endTimestamp,
            _saleTierDetails.paused,
            _saleTierDetails.mintLimit
        );
    }

    function adjustSaleTierPaused(uint8 _index, bool _paused) public onlyOwner {
        saleTierDetails[_index].paused = _paused;
    }

    function adjustMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(
            _maxSupply <= 7777,
            "Max supply can only be adjusted to lower than 7777."
        );
        maxSupply = _maxSupply;
    }

    function adjustMaxSupplyInPublicSale(uint256 _maxSupplyInPublicSale) public onlyOwner {
        require(
            _maxSupplyInPublicSale <= maxSupply,
            "Max supply in public sale can only be adjusted to lower than max supply."
        );
        maxSupplyInPublicSale = _maxSupplyInPublicSale;
    }


    function withdrawFunds() public onlyOwner {
        uint256 funds = address(this).balance;

        (bool succ, ) = payable(msg.sender).call{value: funds}("");
        require(succ, "transfer failed");
    }

    function setDegenesisAddress(address _degenesisAddress) public onlyOwner {
        degenesisAddress = _degenesisAddress;
    }

    function setDegenheimRendererAddress(address _degenheimRendererAddress) public onlyOwner {
        degenheimRendererAddress = _degenheimRendererAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    /*
  _____  ______          _____    ______ _    _ _   _  _____ _______ _____ ____  _   _  _____ 
 |  __ \|  ____|   /\   |  __ \  |  ____| |  | | \ | |/ ____|__   __|_   _/ __ \| \ | |/ ____|
 | |__) | |__     /  \  | |  | | | |__  | |  | |  \| | |       | |    | || |  | |  \| | (___  
 |  _  /|  __|   / /\ \ | |  | | |  __| | |  | | . ` | |       | |    | || |  | | . ` |\___ \ 
 | | \ \| |____ / ____ \| |__| | | |    | |__| | |\  | |____   | |   _| || |__| | |\  |____) |
 |_|  \_\______/_/    \_\_____/  |_|     \____/|_| \_|\_____|  |_|  |_____\____/|_| \_|_____/ 
*/

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return IDegenheimRenderer(degenheimRendererAddress).tokenURI(_tokenId);
    }
}