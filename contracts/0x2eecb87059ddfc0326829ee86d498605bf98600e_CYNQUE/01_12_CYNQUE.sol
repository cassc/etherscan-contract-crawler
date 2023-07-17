// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*
CYNQUE.sol
Written by: mousedev.eth
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract CYNQUE is ERC721, Ownable{
    using Strings for uint256;

    string public baseURI;
    string public contractURI;
    uint256 public nextTokenId = 1;

    address public passportAddress;
    
    //CRA<<
        uint256 public collectionSize;

        // Length of the auction in blocks
        uint256 public duration;

        // Starting block number of the auction
        uint256 public startBlock;

        // Length of an auction step in blocks
        uint256 public stepDuration;

        // Starting price of the auction in wei
        uint256 public startPrice;

        // Floor price of the auction in wei
        uint256 public floorPrice;

        // Magnitude of price change per step
        uint256 public priceDeltaUp;
        uint256 public priceDeltaDown;

        // Expected rate of mints per step (calculated)
        uint256 public expectedStepMintRate;

        // Current step in the auction, starts at 1
        uint256 internal _currentStep;

        uint256 internal auctionId;

        // Mapping from step to number of mints at that step
        mapping(uint256 => mapping(uint256 => uint256)) internal _mintsPerStep;

        // Mapping from step to price at that step
        mapping(uint256 => uint256) internal _pricePerStep;
    //>>

    mapping(uint256 => bool) public passportHasMinted;

    mapping(uint256 => uint256) public passportToCynque;
    mapping(uint256 => uint256) public cynqueToPassport;

    mapping(address => uint256) public quantityOfPublicMinted;

    //EIP2981
    uint256 private _royaltyBps;
    address private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    //Custom errors
    error MaxPassportMintExceeded();
    error PublicSaleNotLive();
    error NotOwnerOfCynque();
    error TeamMintAlreadyDone();
    error MaxMintedOnPublicSale();
    error IncorrectQuantity();

    error MaxSupplyExceeded();
    error PassportAlreadyMinted();
    error NotOwnerOfPassport();
    error NotEnoughEtherSent();

    constructor(uint256 startBlock_)
        ERC721("Lost Children of Andromeda: CYNQUE Prototypes", "CYNQUE")
    {
        collectionSize = 1111;
        duration = 3046; //~11 hours
        startBlock = startBlock_;
        stepDuration = 69; //~15 minutes
        startPrice = 0;
        floorPrice = 0;
        priceDeltaUp = 0.11 ether;
        priceDeltaDown = 0.055 ether;
        auctionId = 0;

        expectedStepMintRate = collectionSize / (duration / stepDuration);

        // Auction steps start at 1
        _currentStep = 1;
        _pricePerStep[1] = startPrice;

        baseURI = "https://api.lostchildren.xyz/api/cynques/";
        passportAddress = 0x4aa0247996529009a1D805AccC84432CC1b5da5D;
    }

    /*
   __  __                  ______                 __  _
  / / / /_______  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
 / / / / ___/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
/ /_/ (__  )  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
\____/____/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
*/
    function mintCynqueWithPassports(
        uint256 _quantity, 
        uint256[] memory passportIds,
        uint8 v, bytes32 r, bytes32 s
    ) external payable {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _quantity, passportIds));
        bytes32 hashedMessage = hashMessage(message);
        address addr = ecrecover(hashedMessage, v, r, s);
        require(addr == msg.sender, "Invalid sig!");

        if (_quantity < 1 || _quantity > 4) revert IncorrectQuantity();
        if(passportIds.length > _quantity) revert MaxPassportMintExceeded();
        if (quantityOfPublicMinted[msg.sender] + _quantity > 4)
            revert MaxMintedOnPublicSale();

        (uint256 auctionStep, uint256 price) = _getCurrentStepAndPrice();
        // Update auction state to the new step and new price
        if (auctionStep > _currentStep) {
            _pricePerStep[auctionStep] = price;
            _currentStep = auctionStep;
        }

        uint256 discountPrice = ((price * 8)/10) * passportIds.length;
        uint256 totalPrice = ((_quantity - passportIds.length) * price) + discountPrice;

        if (msg.value < totalPrice)
            revert NotEnoughEtherSent();

        for (uint256 i = 0; i < passportIds.length; i++) {
            //Require this passport hasn't minted
            if (passportHasMinted[passportIds[i]] == true)
                revert PassportAlreadyMinted();

            //Make sure they own this passport
            if (IERC721(passportAddress).ownerOf(passportIds[i]) != msg.sender)
                revert NotOwnerOfPassport();

            //Mark minted before minting.
            passportHasMinted[passportIds[i]] = true;

            //Store that this passport is connected to the next cynque
            passportToCynque[passportIds[i]] = nextTokenId;

            //Store that the next cynque is connected to this passport
            cynqueToPassport[nextTokenId] = passportIds[i];
        }

        for (uint256 i = 0; i < _quantity; i++) {
            mintCynque();            
        }

        quantityOfPublicMinted[msg.sender] += _quantity;
        _mintsPerStep[auctionId][auctionStep] += _quantity;
    }

    function cynqueronize(uint256 passportId, uint256 cynqueTokenId) external {
        //Make sure they own this passport
        if (IERC721(passportAddress).ownerOf(passportId) != msg.sender)
            revert NotOwnerOfPassport();

        //Make sure they own this passport
        if (ownerOf(cynqueTokenId) != msg.sender) revert NotOwnerOfCynque();

        //Store that this passport is connected to this cynque.
        passportToCynque[passportId] = cynqueTokenId;

        //Store that this cynque is connected to this passport.
        cynqueToPassport[cynqueTokenId] = passportId;
    }

    function mintCynque() internal {
        //Require under max supply
        if (nextTokenId > 1111) revert MaxSupplyExceeded();

        _mint(msg.sender, nextTokenId);

        unchecked {
            ++nextTokenId;
        }
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    /*
 _    ___                 ______                 __  _
| |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
| | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
| |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
|___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
*/

    function walletOfOwner(address _address)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        //Thanks 0xinuarashi for da inspo

        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _addedTokens;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (ownerOf(i) == _address) {
                _tokens[_addedTokens] = i;
                _addedTokens++;
            }

            if (_addedTokens == _balance) break;
        }
        return _tokens;
    }

    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist!");
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        returns (address, uint256)
    {
        return (_royaltyRecipient, (value * _royaltyBps) / 10000);
    }

    /*
   ____                              ______                 __  _
  / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
 / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
/ /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
\____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
*/

    function communitySweep(uint256 _quantity) external onlyOwner {
        for (uint256 i = 0; i < _quantity; i++) {
            mintCynque();
        }
    }

    function teamMint() external onlyOwner {
        if (nextTokenId > 1) revert TeamMintAlreadyDone();

        for (uint256 i = 0; i < 110; i++) {
            mintCynque();
        }
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setPassportAddress(address _passportAddress) external onlyOwner {
        passportAddress = _passportAddress;
    }

    function withdraw() public onlyOwner {
        (bool succ, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(succ, "transfer failed");
    }

    function setPrice(uint256 _price) external onlyOwner {
        _pricePerStep[_currentStep] = _price;
    }

    function restartAuction(
        uint256 duration_,
        uint256 startBlock_,
        uint256 stepDuration_,
        uint256 startPrice_,
        uint256 floorPrice_,
        uint256 priceDeltaUp_,
        uint256 priceDeltaDown_
    ) external onlyOwner(){
        require(duration_ > 0, "duration_ must be > 0");
        require(startBlock_ > block.number, "Start block must be > current block");
        require(stepDuration_ > 0, "stepDuration_ must be > 0");
        require(startPrice_ >= floorPrice_, "startPrice_ must be >= floorPrice_");
        require(priceDeltaUp_ > 0 && priceDeltaDown_ > 0, "priceDeltas must be > 0");

        duration = duration_;
        startBlock = startBlock_;
        stepDuration = stepDuration_;
        startPrice = startPrice_;
        floorPrice = floorPrice_;
        priceDeltaUp = priceDeltaUp_;
        priceDeltaDown = priceDeltaDown_;
        auctionId++;

        expectedStepMintRate = collectionSize / (duration / stepDuration);

         // Auction steps start at 1
        _currentStep = 1;
        _pricePerStep[1] = startPrice;
    }

    /**
  ________  ___     ______  ___  _____________________  _  ______
 / ___/ _ \/ _ |   / __/ / / / |/ / ___/_  __/  _/ __ \/ |/ / __/
/ /__/ , _/ __ |  / _// /_/ /    / /__  / / _/ // /_/ /    /\ \  
\___/_/|_/_/ |_| /_/  \____/_/|_/\___/ /_/ /___/\____/_/|_/___/                                                                     
*/
    /**
     * ROYALTY FUNCTIONS
     */
    function updateRoyalties(address payable recipient, uint256 bps)
        external
        onlyOwner
    {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }



    /**
     * @dev Get the current step of the auction based on the elapsed time.
     */
    function _getStep() internal view returns (uint256) {
        // Note: In this implementation, this can never happen
        // because startBlock is always set to the block.number on deploy
        // in the constructor - but a production version of this contract
        // would want to explicitly set the startBlock of the auction
        require(block.number >= startBlock, "Auction has not started!");

        uint256 elapsedBlocks = block.number - startBlock;

        // The auction can't last longer than the auction's duration
        if (elapsedBlocks > duration) {
            elapsedBlocks = duration;
        }

        uint256 step = Math.ceilDiv(elapsedBlocks, stepDuration);

        // Steps start at 1
        return step > 0 ? step : 1;
    }

    /**
     * @dev Returns the current auction price given the current and previous step.
     */
    function _getAuctionPrice(uint256 currStep, uint256 prevStep) internal view returns (uint256) {
        require(prevStep > 0, "prevStep must be > 0");
        require(_currentStep >= prevStep, "_currentStep must be >= prevStep");
        require(currStep >= prevStep, "currStep must be >= prevStep");

        uint256 price = _pricePerStep[prevStep];
        uint256 passedSteps = currStep - prevStep;
        uint256 numMinted;

        while (passedSteps > 0) {
            numMinted = _mintsPerStep[auctionId][prevStep];

            // More than the expected rate, raise the price
            if (numMinted > expectedStepMintRate) {
                price += priceDeltaUp;
            }
            // Less than the expected rate, lower the price
            else if (numMinted < expectedStepMintRate) {
                if (priceDeltaDown > price - floorPrice) {
                    price = floorPrice;
                } else {
                    price -= priceDeltaDown;
                }
            }
            // If numMinted == expectedStepMintRate, keep the same price

            prevStep += 1;
            passedSteps -= 1;
        }

        return price;
    }

    /**
     * @dev Returns a tuple of the current step and price.
     */
    function _getCurrentStepAndPrice() internal view returns (uint256, uint256) {
        uint256 step = _getStep();

        // False positive guarding against using strict equality checks
        // Shouldn't be a problem here because we check for > and < cases
        // slither-disable-next-line incorrect-equality
        if (step == _currentStep) {
            return (_currentStep, _pricePerStep[_currentStep]);
        } else if (step > _currentStep) {
            return (step, _getAuctionPrice(step, _currentStep));
        } else {
            revert("Step is < _currentStep");
        }
    }

    /**
     * @dev Returns the current auction price.
     */
    function getCurrentAuctionPrice() external view returns (uint256, uint256) {
        (uint256 step, uint256 price) = _getCurrentStepAndPrice();

        return (step, price);
    }
}