pragma solidity >=0.8.0 <0.9.0;

/**
    @notice     Used to generate two dice rolls.
                These are pseudo-random numbers.
                The first dice roll is exploitable as any smart contract can determine its value.
                The second dice roll includes the first dice roll, as well as the hash of a future block.
                Therefore the second dice roll is not available at the time the first dice roll is committed to.

                Inspired by the concept of commit-reveal, but simplified to save gas.

                Requires a trusted party to roll the second dice. However anyone can choose to audit/verify the second dice roll.

    @dev        maxDiceRoll - largest possible dice roll
                offset - number of blocks to look into the future for the second dice roll

    @author Immutable
*/

contract Dice {
    uint256 maxDiceRoll;
    uint8 offset;

    event SecondDiceRoll(
        uint256 indexed _firstDiceRoll,
        uint256 indexed _commitBlock,
        uint256 _secondDiceRoll
    );

    /// @param _maxDiceRoll largest dice roll possible
    /// @param _offset how many blocks to look into the future for second dice roll
    constructor(uint256 _maxDiceRoll, uint8 _offset) {
        maxDiceRoll = _maxDiceRoll;
        offset = _offset;
    }

    /// @notice Take the exploitable 'random' number from a previous block already committed to, and enhance it with the blockhash of a later block
    /// @param _firstDiceRoll The exploitable 'random' number generated previously
    /// @param _commitBlock The block that _firstDiceRoll was generated in
    /// @return A new 'random' number that was not available at the time of _commitBlock
    function getSecondDiceRoll(uint256 _firstDiceRoll, uint256 _commitBlock)
        public
        view
        returns (uint256)
    {
        return _getSecondDiceRoll(_firstDiceRoll, _commitBlock);
    }

    /// @notice Take the exploitable 'random' number from a previous block that was already committed to, and enhance it with the blockhash of a later block. Emit this new number as an event.
    /// @param _firstDiceRoll The exploitable 'random' number generated previously
    /// @param _commitBlock The block that _firstDiceRoll was generated in
    function emitSecondDiceRoll(uint256 _firstDiceRoll, uint256 _commitBlock)
        public
    {
        emit SecondDiceRoll(
            _firstDiceRoll,
            _commitBlock,
            _getSecondDiceRoll(_firstDiceRoll, _commitBlock)
        );
    }

    function _getSecondDiceRoll(uint256 _firstDiceRoll, uint256 _commitBlock)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _firstDiceRoll,
                        _getFutureBlockhash(_commitBlock)
                    )
                )
            ) % maxDiceRoll;
    }

    function _getFutureBlockhash(uint256 _commitBlock)
        internal
        view
        returns (bytes32)
    {
        uint256 delta = block.number - _commitBlock;
        require(delta < offset + 256, "Called too late"); // Only the last 256 blockhashes are accessible to the smart contract
        require(delta >= offset + 1, "Called too early"); // The hash of commitBlock + offset isn't available until the following block
        bytes32 futureBlockhash = blockhash(_commitBlock + offset);
        require(futureBlockhash != bytes32(0), "Future blockhash empty"); // Sanity check to ensure we have a blockhash, which we will due to previous checks
        return futureBlockhash;
    }

    /// @notice Return a "random" number by hashing a variety of inputs such as the blockhash of the last block, the timestamp of this block, the buyers address, and a seed provided by the buyer.
    /// @dev This function is exploitable as a smart contract can see what random number would be generated and make a decision based on that. Must be used with getSecondDiceRoll()
    function getFirstDiceRoll(uint256 _userProvidedSeed)
        public
        view
        returns (uint256 randomNumber)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp,
                        msg.sender,
                        _userProvidedSeed
                    )
                )
            ) % maxDiceRoll;
    }

    /// @return true '_chance%' of the time where _chance is a percentage to 2 d.p. E.g. 1050 for 10.5%
    /// @dev _random must be a random number between 0 and _maxDiceRoll
    function _diceWin(
        uint256 _random,
        uint256 _chance,
        uint256 _maxDiceRoll
    ) internal pure returns (bool) {
        return _random < (_maxDiceRoll * _chance) / _maxDiceRoll;
    }

    /// @dev _random must be a random number between 0 and _maxDiceRoll
    /// @return true when _random falls between _lowerLimit and _upperLimit, where limits are percentages to 2 d.p. E.g. 1050 for 10.5%
    function _diceWinRanged(
        uint256 _random,
        uint256 _lowerLimit,
        uint256 _upperLimit,
        uint256 _maxDiceRoll
    ) internal pure returns (bool) {
        return
            _random < (_maxDiceRoll * _upperLimit) / _maxDiceRoll &&
            _random >= (_maxDiceRoll * _lowerLimit) / _maxDiceRoll;
    }
}