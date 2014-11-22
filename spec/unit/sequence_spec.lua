require 'spec/custom_asserts'
local BehaviourTree = require 'lib/behaviour_tree'

describe('Sequence', function()
  local subject
  before_each(function()
    subject = BehaviourTree.Sequence:new({})
  end)

  describe(':initialize', function()
    it('should copy any attributes to the node', function()
      local node = BehaviourTree:new({testfield = 'foobar'})
      assert.is_equal(node.testfield, 'foobar')
    end)
    it('should register the node if the name is set', function()
      local node = BehaviourTree:new({name = 'foobar'})
      assert.is_equal(BehaviourTree.getNode('foobar'), node)
    end)
  end)

  describe(':start', function()
    it('should set the object', function()
      assert.is_nil(subject.object)
      subject:start('foobar')
      assert.is_equal(subject.object, 'foobar')
    end)
    it('should set actualTask', function()
      assert.is_nil(subject.actualTask)
      subject:start()
      assert.is_equal(subject.actualTask, 1)
    end)
  end)

  describe(':finish', function()
    it('has a finish method', function()
      assert.is_function(subject.finish)
    end)
  end)

  describe(':run', function()
    it('should call _run if it still has tasks', function()
      subject.nodes = {BehaviourTree.Task:new()}
      subject:start()
      stub(subject, '_run')
      subject:run()
      assert.stub(subject._run).was.called()
    end)
    it('should not call run if it has no tasks', function()
      subject.nodes = {}
      subject:start()
      stub(subject, '_run')
      subject:run()
      assert.stub(subject._run).was_not.called()
    end)
  end)

  describe(':_run', function()
    local node
    before_each(function()
      node = BehaviourTree.Task:new() 
      subject.nodes = {node}
      subject:start()
    end)

    it('should set the current node', function()
      subject:_run()
      assert.is_equal(subject.node, node)
    end)
    it('should get the current node from the registry', function()
      BehaviourTree.register('mynode', node)
      subject.nodes = {'mynode'}
      subject:_run()
      assert.is_equal(subject.node, node)
    end)
    it('should set the current nodes control', function()
      stub(node, 'setControl')
      subject:_run()
      assert.stub(node.setControl).was.called_with(node, subject)
    end)
    it('should call start on the current node if first run', function()
      stub(node, 'start')
      subject:_run('foo')
      assert.stub(node.start).was.called_with(node, 'foo')
    end)
    it('should not call start on the current node if running', function()
      subject.node = node
      subject.nodeRunning = true
      stub(node, 'start')
      subject:_run()
      assert.stub(node.start).was_not.called()
    end)
    it('should call run on the current node', function()
      stub(node, 'run')
      subject:_run('foo')
      assert.stub(node.run).was.called_with(node, 'foo')
    end)
  end)

  describe(':setObject', function()
    it('should set the object on the node', function()
      subject:setObject('foobar')
      assert.is_equal(subject.object, 'foobar')
    end)
  end)

  describe(':setControl', function()
    it('should set the controller on the node', function()
      subject:setControl('foobar')
      assert.is_equal(subject.control, 'foobar')
    end)
  end)

  describe(':running', function()
    local node
    before_each(function()
      node = BehaviourTree.Task:new() 
      subject.control = {running = function()end}
      subject.node = node
    end)
    it('should set nodeRunning', function()
      subject:running()
      assert.is_true(subject.nodeRunning)
    end)
    it('should call running on control', function()
      stub(subject.control, 'running')
      subject:running()
      assert.stub(subject.control.running).was.called()
    end)
  end)

  describe(':success', function()
    local node
    before_each(function()
      node = BehaviourTree.Task:new() 
      subject.actualTask = 1
      subject.control = {success = function()end}
      subject.nodeRunning = true
      subject.nodes = {node}
      subject.node = node
    end)
    it('should set nodeRunning as nil', function()
      subject:success()
      assert.is_false(subject.nodeRunning)
    end)
    it('should call finish on current node', function()
      stub(node, 'finish')
      subject:success()
      assert.stub(node.finish).was.called()
    end)
    it('should set current node as nil', function()
      subject:success()
      assert.is_nil(subject.node)
    end)
    it('should call success on control if no more tasks', function()
      stub(subject.control, 'success')
      subject:success()
      assert.stub(subject.control.success).was.called()
    end)
    it('should call _run if there are more tasks', function()
      subject.nodes = {'a', 'b'}
      stub(subject, '_run')
      subject:success()
      assert.stub(subject._run).was.called()
    end)
  end)

  describe(':fail', function()
    local node
    before_each(function()
      node = BehaviourTree.Task:new() 
      subject.control = {fail = function()end}
      subject.nodeRunning = true
      subject.node = node
    end)
    it('should set nodeRunning as nil', function()
      subject:fail()
      assert.is_false(subject.nodeRunning)
    end)
    it('should call finish on current node', function()
      stub(node, 'finish')
      subject:fail()
      assert.stub(node.finish).was.called()
    end)
    it('should set current node as nil', function()
      subject:fail()
      assert.is_nil(subject.node)
    end)
  end)

end)
