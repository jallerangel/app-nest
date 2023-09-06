import { Resolver, Query, Mutation } from '@nestjs/graphql';
import { ToDo } from './entity/todo.entity';

@Resolver()
export class TodoResolver {

    @Query( () => [ToDo], {name: 'todos'})
    findAll(): [ToDo] {
        return [{ id: 212, description: 'Este es un todo', done: false}]
    }

    findOne() {

    }

    // @Mutation()
    createToDo() {
    
    } 
    // @Mutation()
    updateToDo() {

    }

    // @Mutation()
    removeToDo() {

    }
}
