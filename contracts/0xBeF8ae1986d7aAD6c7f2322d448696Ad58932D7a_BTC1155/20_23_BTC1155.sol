// SPDX-License-Identifier: MIT

/// @title This is a fungible ERC1155 token. People will be able to mint (1 mint per day though) everyday, a real open edition. Flippers can still speculate from it since there is a halving process every 4 years.

pragma solidity 0.8.17;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @dev ERC1155Supply: Return total supply of a specific token.
/// @dev ERC1155Holder: This contract is also used as an exchange. It needs to store SATs.
/// @dev ERC2981 and DefaultOperatorFilterer: Royalties determination
/// @dev Ownable: Only to set up descriptions on Opensea. Only the address with Chain Status NFT can collect the mint price.
contract BTC1155 is DefaultOperatorFilterer, ERC1155Supply, ERC1155Holder, ERC2981, ReentrancyGuard, Ownable{

    /// @dev Here we define tokenomics. The halving leads to the possible of speculation even with a open edition.
    /// @dev Initial reward ~ 0.56 BTC, which makes the total supply of BTC1155 around 1155 BTCs.
    uint256 private constant initialReward = 56396484;

    /// @dev Every 8192 (1 << 13) blocks on ETH is one block in BTC1155 contract.
    /// @dev This is around 1 day (1 day ~ 7166 blocks on 2023/02/07)
    uint256 private constant blockLengthETH = 8192;

    /// @dev We get a halving around every 4 years.
    /// @dev 4 years ~ 1245 days.
    /// @dev Every 1024 blocks in BTC1155 contract leads to a halving.
    /// @dev Every 2097152 blocks on Ethereum leads to a halving.
    uint256 private constant halvingPeriod = 1024;

    /// @dev Every transfer from someone to someone else burn 10 satoshis.
    uint256 private constant transactionFees = 10;

    /// @dev Current block number.
    uint256 private blockNumber;

    /// @dev The electricity fee to mine satoshis/BTCs.
    uint256 private electricityCost = 0.001 ether;

    /// @notice 1 BTC = 100000000 SAT.
    uint256 public constant BTCtoSAT = 10 ** 8;

    /// @dev Register the transaction fees collected to reward the next miner.
    uint256 private transactionFeesCollected;

    /// @notice How many electricities were used to mine BTCs
    uint256 public electricityFeeCollected;

    /// @dev TokenId, for better readability in the followings.
    uint256 private constant CHAINSTATUS = 0;
    uint256 private constant SWAPSTATUS = 1;
    uint256 private constant BTC = 2;
    uint256 private constant SAT = 3;
    uint256 private constant LP = 4;

    /// @dev names of different tokenId. Used in uri(tokenId)
    string[] private names = ["Chain Status", "Swap Status", "BTC", "SAT", "LP"];

    /// @dev Very useful constant in different functions.
    address private self = address(this);

    string public name = "BTC1155";
    string public symbol = "BTC";

  constructor() ERC1155("BTC1155") {
      _mint(msg.sender, CHAINSTATUS, 1, "");
      _mint(self, SWAPSTATUS, 1, "");
  }

  // -------------------------------------------------------------------------------------------------------------------
  // ------------------------------------------------ mine -------------------------------------------------------------
  // -------------------------------------------------------------------------------------------------------------------

  /// @notice Use this function to mine more SAT/BTC! Set value to `electricityCost`.
  function mine() external payable nonReentrant{
      /*
         A real open edition: everyone will still be able to mint after the first mints.
         Not a time-limited one like https://opensea.io/assets/ethereum/0x8c335a5e0cf05eca62ca1e49afa48531b694824e/10 and much more.
         This also motivate the team to keep building, not buying a G-wagon right after sold out.
         Flippers can also speculate with the halving event.
      */
      require(msg.value >= electricityCost, "You pay the electricity, don't you?"); // price: 0.001. 
      electricityFeeCollected += electricityCost;
      require(block.number >= blockNumber * blockLengthETH, "Next block not available yet");
      blockNumber++;

      uint256 blockReward = getBlockReward();
      _mint(msg.sender, SAT, blockReward + transactionFeesCollected, ""); // mine Block reward + transaction fees.
      transactionFeesCollected = 0;
  }

  /// @notice get current mining reward.
  /// @return Mining reward.
  function getBlockReward() public view returns (uint256){
      return initialReward >> (blockNumber / halvingPeriod);
  }

  // -------------------------------------------------------------------------------------------------------------------
  // ----------------------------------------------- convert -----------------------------------------------------------
  // -------------------------------------------------------------------------------------------------------------------
  /// @notice Convert BTC to SAT at 1 BTC = 1e8 SAT.
  /// @param amountBTC The amount of BTC that you want to change to SAT.
  function convertBTCtoSAT(uint256 amountBTC) external{
      require(balanceOf(msg.sender, BTC) >= amountBTC, "BTC not enough");
      _burn(msg.sender, BTC, amountBTC);
      _mint(msg.sender, SAT, amountBTC * BTCtoSAT, "");
  }
  /// @notice Convert SAT to BTC at 1 BTC = 1e8 SAT.
  /// @dev Raise error if amountSAT is not a multiplier of 1e8
  /// @param amountSAT The amount of SAT that you want to change to BTC.
  function convertSATtoBTC(uint256 amountSAT) external{
      require(balanceOf(msg.sender, SAT) >= amountSAT, "SAT not enough");
      require(amountSAT % (BTCtoSAT) == 0, "Not available amount");
      _burn(msg.sender, SAT, amountSAT);
      _mint(msg.sender, BTC, amountSAT / BTCtoSAT, "");
  }
  // -------------------------------------------------------------------------------------------------------------------
  // ------------------------------------------------ Swap -------------------------------------------------------------
  // -------------------------------------------------------------------------------------------------------------------
  // -------------------------------------
  // --------------- LP  -----------------
  // -------------------------------------

  /// @dev getting reserves of SAT, ETH in the pool and the supply of LP.
  /// @return reserveSAT, reserveETH, supplyLP.
  function getReserves() public view returns (uint256, uint256, uint256){
      return (balanceOf(self, SAT), self.balance - electricityFeeCollected, totalSupply(LP));
  }

  /// @dev Get the square root of an unsigned integer. Used to determine how many LP tokens to mine.
  /// @param x The number to get the square root.
  /// @return y Square root of x.
  function sqrt(uint x) internal pure returns (uint y) {
      uint z = (x + 1) / 2;
      y = x;
      while (z < y) {
          y = z;
          z = (x / z + z) / 2;
      }
  }

  /// @notice Use this function to check how many ETH you need to add liquidity.
  /// @param amountBTC the amount of BTC to add to the pool.
  /// @param amountSAT the amount of SAT to add to the pool.
  /// @return The ETH needed to add liquidity with given amounts of BTC and SAT.
  function getETHNeededToAddLiquidity(uint256 amountBTC, uint256 amountSAT) public view returns (uint256){
      (uint256 reserveSAT, uint256 reserveETH, uint256 reserveLP) = getReserves();
      require(reserveLP > 0, "Pool needs to be created");
      uint256 deltaSAT = amountBTC * BTCtoSAT + amountSAT;
      return divRound(reserveETH * deltaSAT, reserveSAT);
  }

  /// @notice Use this function to add liquidity. Ensure you check the ETH needed with getETHNeededToAddLiquidity first.
  /// @param amountBTC the amount of BTC to add to the pool.
  /// @param amountSAT the amount of SAT to add to the pool.
  function addLiquidity(uint256 amountBTC, uint256 amountSAT) external payable nonReentrant{
      require(balanceOf(msg.sender, BTC) >= amountBTC, "BTC not enough");
      require(balanceOf(msg.sender, SAT) >= amountSAT, "SAT not enough");
      (uint256 reserveSAT, uint256 reserveETH, uint256 reserveLP) = getReserves();
      if (reserveLP == 0){ // New pool
          require(msg.value > 0, "You need to add both BTC/SAT and ETH at the same time");
          if (amountBTC > 0){
              _burn(msg.sender, BTC, amountBTC);
              _mint(self, SAT, amountBTC * BTCtoSAT, "");
          }
          if (amountSAT > 0){
              _safeTransferFrom(msg.sender, self, SAT, amountSAT, "");
          }
          uint256 minimumLiquidity = 10 ** 10;
          _mint(msg.sender, LP, sqrt((amountBTC * BTCtoSAT + amountSAT) * msg.value) - minimumLiquidity, ""); // Mint liquidity token
          _mint(self, LP, minimumLiquidity, "");
      }
      else{ // Add to existing liquidities
          reserveETH -= msg.value;
          uint256 ETHNeeded = divRound(reserveETH * (amountBTC * BTCtoSAT + amountSAT), reserveSAT);
          require(msg.value >= ETHNeeded, "Eth not enough");
          payable(msg.sender).transfer(msg.value - ETHNeeded); // Return unused ether back to the msg sender.
          if (amountBTC > 0){
              _burn(msg.sender, BTC, amountBTC);
              _mint(self, SAT, amountBTC * BTCtoSAT, "");
          }
          if (amountSAT > 0){
              _safeTransferFrom(msg.sender, self, SAT, amountSAT, "");
          }
          _mint(msg.sender, LP, sqrt((amountBTC * BTCtoSAT + amountSAT) * ETHNeeded), "");
      }
  }

  /// @notice Use this function to remove liquidity.
  /// @param amountLP the amount of LP to remove from the pool.
  function removeLiquidity(uint256 amountLP) external nonReentrant{
      (uint256 reserveSAT, uint256 reserveETH, uint256 reserveLP) = getReserves();
      require(balanceOf(msg.sender, LP) >= amountLP, "LP not enough");
      _burn(msg.sender, LP, amountLP);
      uint256 returnedSAT = reserveSAT * amountLP / reserveLP;
      returnSATWisely(returnedSAT, msg.sender);
      payable(msg.sender).transfer(reserveETH * amountLP / reserveLP);
  }

  // -------------------------------------
  // -------------- SWAP -----------------
  // -------------------------------------

  /// @dev add one if a is not divided by b.
  /// @param a Dividend
  /// @param b Divisor
  /// @return Quotient
  function divRound(uint256 a, uint256 b) internal pure returns (uint256){
      return a % b == 0 ? (a/b) : ((a/b) + (1));
  }

  /// @notice Get the price when adding tokens to the pool.
  /// @dev The fee is fixed at 0.5% here. The price returned is with rounding error.
  /// @param _assetBoughtAmount Amount to buy.
  /// @param _assetSoldReserve Reserve in the pool of the token to sell
  /// @param _assetBoughtReserve Reserve in the pool of the token to buy.
  /// @return price The price.
  function getBuyPrice(uint256 _assetBoughtAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) public pure returns (uint256 price){
      require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "Exchange error: EMPTY_RESERVE");
      uint256 numerator = _assetSoldReserve * (_assetBoughtAmount) * (200);
      uint256 denominator = (_assetBoughtReserve - (_assetBoughtAmount)) * (199);
      (price) = divRound(numerator, denominator);
      return price; // Will add 1 if rounding error.
  }

  /// @notice Get the price when removing tokens from the pool.
  /// @dev The fee is fixed at 0.5% here. There is no rounding error here to favorite the exchange.
  /// @param _assetSoldAmount Amount to sell.
  /// @param _assetSoldReserve Reserve in the pool of the token to sell
  /// @param _assetBoughtReserve Reserve in the pool of the token to buy.
  /// @return price The price.
  function getSellPrice(uint256 _assetSoldAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) public pure returns (uint256  price){
      require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "Exchange error: EMPTY_RESERVE");
      uint256 _assetSoldAmount_withFee = _assetSoldAmount * 199;
      uint256 numerator = _assetSoldAmount_withFee * _assetBoughtReserve;
      uint256 denominator = _assetSoldReserve * 200 + _assetSoldAmount_withFee;
      return numerator / denominator;
  }

  /// @dev This function return SAT by changing them to BTC first.
  /// @param SATToReturn_ The amount of SAT to return. We assumed every BTC is already changed to SAT here.
  /// @param to The address to get the SAT(BTC)s.
  function returnSATWisely(uint256 SATToReturn_, address to) internal {
      if (SATToReturn_ >= BTCtoSAT){ // Give BTC then SAT
          _mint(to, BTC, SATToReturn_ / BTCtoSAT, "");
          _burn(self, SAT, SATToReturn_ / BTCtoSAT * BTCtoSAT);
      }
      _safeTransferFrom(self, to, SAT, SATToReturn_ % BTCtoSAT, "");
  }

  /// @notice Swap your SAT/BTC to get ETH.
  /// @param amountBTC The amount of BTC
  /// @param amountSAT The amount of SAT
  function swapForETH(uint256 amountBTC, uint256 amountSAT) external nonReentrant{
      (uint256 reserveSAT, uint256 reserveETH, ) = getReserves();
      require(balanceOf(msg.sender, BTC) >= amountBTC, "BTC not enough");
      require(balanceOf(msg.sender, SAT) >= amountSAT, "SAT not enough");
      if (amountBTC > 0){
          _burn(msg.sender, BTC, amountBTC);
          _mint(self, SAT, amountBTC * BTCtoSAT, "");
      }
      _safeTransferFrom(msg.sender, self, SAT, amountSAT, "");
      payable(msg.sender).transfer(getSellPrice(amountBTC * BTCtoSAT + amountSAT, reserveSAT, reserveETH));
  }

  /// @notice Swap your ETH to get SAT
  function swapForSAT() external payable nonReentrant{
      (uint256 reserveSAT, uint256 reserveETH, ) = getReserves();
      reserveETH -= msg.value;
      returnSATWisely((199 * msg.value * reserveSAT) / (200 * reserveETH + 199 * msg.value), msg.sender);
  }

  /// @notice Swap SATs for exact amount of ETH.
  /// @param amountETH The amount of ETH you want.
  function swapForExactETH(uint256 amountETH) external nonReentrant{
      (uint256 reserveSAT, uint256 reserveETH, ) = getReserves();
      uint256 SATNeeded = divRound(200 * reserveSAT * amountETH, 199 * (reserveETH - amountETH));
      if (balanceOf(msg.sender, SAT) >= SATNeeded){
          _safeTransferFrom(msg.sender, self, SAT, SATNeeded, "");
      }
      else{ // Burn 1 btc
          _burn(msg.sender, BTC, 1);
          _mint(msg.sender, SAT, BTCtoSAT, "");
          _safeTransferFrom(msg.sender, self, SAT, SATNeeded, "");
      }
      payable(msg.sender).transfer(amountETH);
  }

  /// @notice Swap ETH for exact amount of SAT.
  /// @param amountSAT The amount of SAT you want.
  function swapForExactSAT(uint256 amountSAT) external payable nonReentrant{
      (uint256 reserveSAT, uint256 reserveETH, ) = getReserves();
      reserveETH -= msg.value;
      uint256 ETHNeeded = divRound(200 * amountSAT * reserveETH, 199 * (reserveSAT - amountSAT));
      require(msg.value >= ETHNeeded, "Eth not enough");
      payable(msg.sender).transfer(msg.value - ETHNeeded);
      returnSATWisely(amountSAT, msg.sender);
  }

  // -------------------------------------------------------------------------------------------------------------------
  // ------------------------------------------- TokenUri: images --------------------------------------------------
  // -------------------------------------------------------------------------------------------------------------------

  struct chainStatus{
      uint256 blockNumber;
      uint256 blockReward;
      uint256 nextHalving;
      uint256 transactionFees;
      string currentSupply;
  }
  /// @notice Get current chain status with this function
  /// @dev Use this to render/do anyting you want.
  /// @return cS The chain status.
  function getCurrentChainStatus() public view returns (chainStatus memory cS){
      cS.blockNumber = blockNumber;
      cS.blockReward = getBlockReward();
      cS.nextHalving = halvingPeriod * (blockNumber / halvingPeriod + 1) - blockNumber;
      cS.transactionFees = transactionFeesCollected;
      cS.currentSupply = stringRatio(totalSupply(SAT) + BTCtoSAT * totalSupply(BTC) - transactionFeesCollected, BTCtoSAT);
  }

  /// @dev Return val1 / val2 with 3 digits decimals in the end.
  function stringRatio(uint256 val1, uint256 val2) internal pure returns (string memory){
      if (val2 == 0) val2 = 1;
      uint256 ent = val1 / val2;
      uint256 dec = (val1 - ent * val2) / (val2 / 10 ** 3);
      if (ent > 0 || dec > 0){
          return string.concat(
              Strings.toString(ent),
              ".",
              dec < 100? "0": "",
              dec < 10? "0": "",
              Strings.toString(dec)
          );
      }
      else{
          return "0";
      }
  }
  /// @dev Add text to a svg
  /// @param text The text to add
  /// @param x The x position
  /// @param y The y position
  /// @param type_ In the end or at the beginning.
  /// @return A string which gives the underlined text in svg format.
  function addText(string memory text, string memory x, string memory y, bool type_) internal pure returns (string memory){
      return string(
          abi.encodePacked(
              ' <text x="', x,
              '0%" y="', y,
              '0%" class="b ', type_? 's': 'e',
              '">', text,
              '</text> <line x1="', x,
              '0%" y1="', y,
              '1%" x2="90%" y2="', y, 
              '1%" stroke="#A2CCD6" stroke-width="1px"/>'
          )
      );
  }

  /// @dev image changes according to different tokenId.
  /// @param tokenId The token id
  /// @return A svg file encoded in base64.
  function image(uint256 tokenId) internal view returns (string memory){
      if (tokenId == CHAINSTATUS){
          chainStatus memory cS = getCurrentChainStatus();
          return string(
              string.concat(
                  "data:image/svg+xml;base64,",
                  Base64.encode(
                      bytes(
                          string.concat(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.b {font-family: helvetica; font-size: 16px; dominant-baseline: bottom;}.s { fill: #F0A8AA; text-anchor: start;} .e {fill: #E5E6D9; text-anchor: end;}</style> <rect width="100%" height="100%" fill="#2F2D30" /><text x="50%" y="8%" dominant-baseline="middle" text-anchor="middle" font-size="20px" fill="#E5E6D9" font-family="helvetica">Chain status</text>',
                              /* 
                                  CHAINSTATUS-> return calculated
                                                block number
                                                block reward
                                                Next halving block
                                                transaction fees
                                                Current supply
                              */
                              string.concat(
                                  addText("Block number: ", "1", "2", true),
                                  addText("Block reward: ", "1", "3", true),
                                  addText("Next halving: ", "1", "6", true),
                                  addText("Transaction fees: ", "1", "4", true),
                                  addText("Supply: ", "1", "5", true)
                              ),
                              string.concat(
                                  addText(Strings.toString(cS.blockNumber), "9", "2", false),
                                  addText(string.concat(Strings.toString(cS.blockReward), " SAT"), "9", "3", false),
                                  addText(string.concat(Strings.toString(cS.nextHalving), " block(s)"), "9", "6", false),
                                  addText(string.concat(Strings.toString(cS.transactionFees), " SAT"), "9", "4", false),
                                  addText(string.concat(cS.currentSupply, " BTC"), "9", "5", false)
                              ),
                              '</svg>'
                          )
                      )
                  )
              )
          );
      }
      else if (tokenId == SWAPSTATUS){
          uint256 pooledSAT = balanceOf(self, SAT);
          uint256 pooledETH = self.balance - electricityFeeCollected;
          pooledETH = pooledETH == 0? 1 ether: pooledETH;
          string memory body;
      // SWAPSTATUS ->  return pooled token
          if (pooledSAT == 0){
              body = '<text x="50%" y="50%" text-anchor="middle" fill="#F0A8AA" class="b">No liquidity yet</text>';
          }
          else{
              body = string.concat(
                  string.concat(
                      addText("Pooled SAT:", "1", "2", true),
                      addText("Pooled SAT:", "1", "3", true),
                      addText("Pooled ETH:", "1", "4", true),
                      addText("1 ETH =", "1", "5", true),
                      addText("1 BTC =", "1", "6", true)
              ),
                  string.concat(
                      addText(string.concat(Strings.toString(pooledSAT), " SAT"), "9", "2", false),
                      addText(string.concat(stringRatio(pooledSAT, BTCtoSAT), " BTC"), "9", "3", false),
                      addText(string.concat(stringRatio(pooledETH, 1 ether), " ETH"), "9", "4", false),
                      addText(string.concat(stringRatio(pooledSAT * 10 ** 18, pooledETH), " SAT"), "9", "5", false),
                      addText(string.concat(stringRatio(pooledETH * BTCtoSAT / 1 ether, pooledSAT), " ETH"), "9", "6", false)
                  )
              );
          }

          return string(
              string.concat(
                  "data:image/svg+xml;base64,",
                  Base64.encode(
                      bytes(
                          string.concat(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.b {font-family: helvetica; font-size: 16px; dominant-baseline: bottom;}.s { fill: #F0A8AA; text-anchor: start;} .e {fill: #E5E6D9; text-anchor: end;}</style> <rect width="100%" height="100%" fill="#2F2D30" /><text x="50%" y="8%" dominant-baseline="middle" text-anchor="middle" font-size="20px" fill="#E5E6D9" font-family="helvetica">Swap status</text>',
                              body,
                              '</svg>'
                          )
                      )
                  )
              )
          );
      }
      else{
          return string(
              string.concat(
                  "data:image/svg+xml;base64,",
                  Base64.encode(
                      bytes(
                          string.concat(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.s { fill: #FFFFFF; font-family: helvetica; font-size: 24px; dominant-baseline: bottom; text-anchor: middle;} </style> <rect width="100%" height="100%" fill="#000000" />',
                              '<text x="50%" y="50%" class="s">',
                              ["", "", "1 BTC", "1 SAT", "1 LP"][tokenId],
                              '</text>',
                              '</svg>'
                          )
                      )
                  )
              )
          );
      }
  }

  /// @notice Get token metadata!
  /// @param tokenId The token ID
  /// @return Metadata of tokenId
  function uri(uint256 tokenId) public view override returns (string memory){
      string memory _name = names[tokenId]; 
      string memory _description = "A fungible ERC-1155 token.";
      return string(
          abi.encodePacked(
              "data:application/json;base64,",
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                          '{"name":"', _name,
                          '", "description": "', _description,
                          '", "image":"', image(tokenId), 
                          '"}'
                      )
                  )
              )
          )
      );
  }

  // -------------------------------------------------------------------------------------------------------------------
  // ----------------------------------------------- Only Owner --------------------------------------------------------
  // -------------------------------------------------------------------------------------------------------------------

  /// @notice Manifest yourself if you want to dao this contract. Offer the CHAINSTATUS token with any address with twitter/website/medium account linked. You will also be able to set up royalties on different marketplace, but not this one.
  /// @dev The address who owns the CHAINSTATUS token can withdraw electricities fee. It's not many but if any group wants to dao this contract, try to contact me.
  function withdraw(address to) external nonReentrant{
      require(balanceOf(to, CHAINSTATUS) > 0, "Need to own the status NFT to claim the electricityFee");
      (bool success, ) = to.call{value: electricityFeeCollected}("");
      electricityFeeCollected = 0;
      require(success, "Transfer failed.");
  }

  /// @dev The address who owns the CHAINSTATUS token can withdraw electricities fee. It's not many but if any group wants to dao this contract, try to contact me.
  function withdrawERC20(address to, address currency, uint256 quantity) external nonReentrant{
      require(balanceOf(to, CHAINSTATUS) > 0, "Need to own the status NFT to claim the electricityFee");
      IERC20(currency).transfer(to, quantity);
  }
  /// @dev The address who owns the CHAINSTATUS token can change electricities fee. 
  function changeDifficulty(uint256 difficulty) external nonReentrant{
      require(balanceOf(msg.sender, CHAINSTATUS) > 0, "Need to own the status NFT to change the electricityFee");
      electricityCost = difficulty; // More difficult to mine = more electricity cost.
  }

  // -------------------------------------------------------------------------------------------------------------------
  // ------------------------------------------- Restrict marketplace --------------------------------------------------
  // -------------------------------------------------------------------------------------------------------------------

  /// @dev This is a good way to restrict some weird 0 fee marketplace from getting liquidities. Check opensea royalty restriction.
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  /// @dev This function takes 10 satoshis from the person for the transaction.
  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override{
      if ((operator == from) && (to != address(0)) && (to != self)){ // transfer from somebody to someone else. If the operator is a marketplace then no fee applied.
          uint256 indexSAT = ids.length;
          uint256 totalSAT = 0;
          uint256 indexBTC = ids.length;
          uint256 totalBTC = 0;
          for (uint256 i=0; i < ids.length; ++i){ // Find SAT index. BTC index, too if necessary.
              if(ids[i] == SAT){
                  indexSAT = i;
                  totalSAT += amounts[i];
                  amounts[i] = 0;
              }
              else if (ids[i] == BTC){
                  indexBTC = i;
                  totalBTC += amounts[i];
                  amounts[i] = 0;
              }
          } // End of loop.
          if (totalSAT + transactionFees <= balanceOf(from, SAT)){
              _burn(from, SAT, transactionFees);
          }
          else if (totalSAT >= transactionFees){ // If balance + transactionFees < amount to transfer, then transfer balance - transaction fee to target. Rest 0 in funds.
              _burn(from, SAT, transactionFees);
              totalSAT = balanceOf(from, SAT);
          }
          else if (balanceOf(from, BTC) > totalBTC){ // Not enough SAT, burn 1 BTC for transaction Fees
              _burn(from, BTC, 1);
              _mint(from, SAT, BTCtoSAT - transactionFees, "");
          }
          else{
              _burn(from, BTC, 1);
              totalBTC -= 1;
              if (indexSAT == ids.length){
                  _mint(to, SAT, BTCtoSAT - transactionFees, "");
              }
          }
          if (indexSAT != ids.length){
              amounts[indexSAT] = totalSAT;
          }
          if (indexBTC != ids.length){
              amounts[indexBTC] = totalBTC;
          }
          transactionFeesCollected += transactionFees;
      }
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public override onlyAllowedOperator(from){
      super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981, ERC1155Receiver) returns (bool) {
      return super.supportsInterface(interfaceId);
  }
}