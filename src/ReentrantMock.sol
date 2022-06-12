pragma solidity >=0.6.12;

contract ReentrantMock {
    event SendingLog();

    function log() external {
        emit SendingLog();
    }
}
